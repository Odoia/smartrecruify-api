# frozen_string_literal: true

module Importers
  module Handlers
    class EducationHandler
      Result = Struct.new(:ok, :records, :warnings, :skipped, keyword_init: true)

      def self.call(user:, education_data:, dry_run: false, courses_mapped_to_catalog: [], courses_to_create: [])
        new(user:, education_data:, dry_run:, courses_mapped_to_catalog:, courses_to_create:).call
      end

      def initialize(user:, education_data:, dry_run:, courses_mapped_to_catalog:, courses_to_create:)
        @user  = user
        @dry   = !!dry_run
        @edus  = Array(education_data)
        @map   = Array(courses_mapped_to_catalog)
        @new   = Array(courses_to_create)
      end

      def call
        records  = []
        warnings = []
        skipped  = []

        # 1) Education records
        if model_defined?(:EducationRecord)
          @edus.each do |row|
            attrs = normalize_record(row)
            rec, created = upsert_education_record(attrs)
            records << { model: "EducationRecord", id: rec&.id, created: created, attrs: attrs }
          rescue => e
            warnings << "EducationRecord error: #{e.class}: #{e.message}"
          end
        else
          skipped << "EducationRecord (model not defined)"
        end

        # 2) Course enrollments (mapped ao catálogo)
        if model_defined?(:Course) && model_defined?(:CourseEnrollment)
          @map.each do |enr|
            course_id = enr[:course_id] || enr["course_id"]
            next unless course_id.present?
            course = ::Course.find_by(id: course_id)
            unless course
              warnings << "Course ##{course_id} not found"
              next
            end

            enrollment_attrs = normalize_enrollment(enr).merge(course_id: course.id)
            profile_id = ensure_education_profile_id
            if profile_id
              enrollment_attrs[:education_profile_id] ||= profile_id
            elsif has_column?(::CourseEnrollment, :user_id)
              enrollment_attrs[:user_id] ||= @user.id
            end

            rec, created = upsert_course_enrollment(enrollment_attrs)
            records << { model: "CourseEnrollment", id: rec&.id, created: created, attrs: enrollment_attrs }
          rescue => e
            warnings << "CourseEnrollment error: #{e.class}: #{e.message}"
          end
        else
          skipped << "Course/CourseEnrollment (model not defined)"
        end

        # 3) Cursos a criar (quando não batem no catálogo)
        if model_defined?(:Course) && model_defined?(:CourseEnrollment)
          @new.each do |payload|
            course_attrs, enrollment_attrs = split_course_and_enrollment(payload)

            course = nil
            begin
              course = find_similar_course(course_attrs) || (::Course.new(course_attrs) unless @dry)
              course.save! unless @dry || course.persisted?
            rescue => e
              warnings << "Course create error: #{e.class}: #{e.message}"
              next
            end

            next unless course

            enrollment_attrs = normalize_enrollment(enrollment_attrs).merge(course_id: course.id)
            profile_id = ensure_education_profile_id
            if profile_id
              enrollment_attrs[:education_profile_id] ||= profile_id
            elsif has_column?(::CourseEnrollment, :user_id)
              enrollment_attrs[:user_id] ||= @user.id
            end

            rec, created = upsert_course_enrollment(enrollment_attrs)
            records << { model: "CourseEnrollment", id: rec&.id, created: created, attrs: enrollment_attrs }
          rescue => e
            warnings << "CourseEnrollment create (new) error: #{e.class}: #{e.message}"
          end
        end

        Result.new(ok: true, records: records, warnings: warnings, skipped: skipped)
      end

      private

      # ---------- helpers de schema & existência ----------
      def model_defined?(name)
        Object.const_defined?(name.to_s)
      rescue
        false
      end

      def has_column?(klass, col)
        klass.column_names.include?(col.to_s)
      rescue
        false
      end

      # Se existir EducationProfile, garantimos um perfil por usuário
      def ensure_education_profile_id
        return nil unless model_defined?(:EducationProfile)
        prof = ::EducationProfile.find_or_create_by!(user_id: @user.id) unless @dry
        prof&.id
      rescue
        nil
      end

      # ---------- normalizações ----------
      def normalize_record(row)
        r = row.to_h.symbolize_keys
        {
          user_id:            @user.id,
          degree_level:       r[:degree_level],
          institution_name:   r[:institution_name],
          program_name:       r[:program_name],
          started_on:         iso(r[:started_on]),
          expected_end_on:    iso(r[:expected_end_on]),
          ended_on:           iso(r[:ended_on]),
          status:             r[:status],
          gpa:                (r[:gpa].presence && r[:gpa].to_f),
          transcript_url:     r[:transcript_url]
        }.compact
      end

      def normalize_enrollment(enr)
        e = enr.to_h.symbolize_keys
        {
          status:            e[:status],
          started_on:        iso(e[:started_on]),
          expected_end_on:   iso(e[:expected_end_on]),
          completed_on: [48;79;156;1343;1248t     iso(e[:completed_on]),
          progress_percent:  (e[:progress_percent].presence && e[:progress_percent].to_i)
        }.compact
      end

      # Se o payload juntar dados do curso + matrícula, separamos
      def split_course_and_enrollment(payload)
        p = payload.to_h.symbolize_keys
        course_attrs = {
          name:        p[:name],
          provider:    p[:provider],
          category:    p[:category],
          hours:       (p[:hours].presence && p[:hours].to_i),
          description: p[:description]
        }.compact
        enrollment_attrs = normalize_enrollment(p)
        [course_attrs, enrollment_attrs]
      end

      def iso(val)
        s = val.to_s.strip
        return nil if s.empty? || s == "null"
        y, m, d = s.split("-").map(&:to_i)
        return format("%04d-%02d-%02d", y, (m > 0 ? m : 1), (d > 0 ? d : 1)) if y && y > 0
        nil
      rescue
        nil
      end

      # ---------- upserts ----------
      def upsert_education_record(attrs)
        if @dry
          rec = ::EducationRecord.new(attrs) rescue nil
          return [rec, true]
        end

        # De-dup básica: mesmo user + instituição + programa + início
        rec = ::EducationRecord.where(
          user_id: attrs[:user_id],
          institution_name: attrs[:institution_name],
          program_name: attrs[:program_name],
          started_on: attrs[:started_on]
        ).first

        if rec
          rec.assign_attributes(attrs)
          rec.save! if rec.changed?
          [rec, false]
        else
          [::EducationRecord.create!(attrs), true]
        end
      end

      def upsert_course_enrollment(attrs)
        if @dry
          rec = ::CourseEnrollment.new(attrs) rescue nil
          return [rec, true]
        end

        finder = { course_id: attrs[:course_id] }
        if attrs[:education_profile_id]
          finder[:education_profile_id] = attrs[:education_profile_id]
        elsif has_column?(::CourseEnrollment, :user_id)
          finder[:user_id] = attrs[:user_id]
        end

        rec = ::CourseEnrollment.where(finder).first
        if rec
          rec.assign_attributes(attrs.except(:course_id, :education_profile_id, :user_id))
          rec.save! if rec.changed?
          [rec, false]
        else
          [::CourseEnrollment.create!(attrs), true]
        end
      end

      # ---------- busca de similaridade simples p/ não duplicar Course ----------
      def find_similar_course(attrs)
        scope = ::Course.where("LOWER(name) = ?", attrs[:name].to_s.downcase)
        scope = scope.where("LOWER(provider) = ?", attrs[:provider].to_s.downcase) if attrs[:provider].present?
        scope.first
      rescue
        nil
      end
    end
  end
end
