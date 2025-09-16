# frozen_string_literal: true

module Importers
  module Handlers
    class EmploymentHandler
      Result = Struct.new(:ok, :records, :warnings, :skipped, keyword_init: true)

      def self.call(user:, employment_data:, dry_run: false)
        new(user:, employment_data:, dry_run:).call
      end

      def initialize(user:, employment_data:, dry_run:)
        @user  = user
        @data  = Array(employment_data)
        @dry   = !!dry_run
      end

      def call
        records  = []
        warnings = []
        skipped  = []

        unless model_defined?(:EmploymentRecord)
          skipped << "EmploymentRecord (model not defined)"
          return Result.new(ok: true, records: records, warnings: warnings, skipped: skipped)
        end

        @data.each do |row|
          attrs = normalize_job(row)
          rec, created = upsert_employment_record(attrs)
          records << { model: "EmploymentRecord", id: rec&.id, created: created, attrs: attrs }

          # Experiences (se houver modelo)
          if model_defined?(:EmploymentExperience)
            Array(row[:experiences] || row["experiences"]).each_with_index do |exp_row, idx|
              exp_attrs = normalize_experience(exp_row).merge(employment_record_id: rec&.id)
              exp_attrs[:order_index] ||= idx
              exp, exp_created = upsert_experience(exp_attrs)
              records << { model: "EmploymentExperience", id: exp&.id, created: exp_created, attrs: exp_attrs }
            rescue => e
              warnings << "EmploymentExperience error: #{e.class}: #{e.message}"
            end
          end
        rescue => e
          warnings << "EmploymentRecord error: #{e.class}: #{e.message}"
        end

        Result.new(ok: true, records: records, warnings: warnings, skipped: skipped)
      end

      private

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

      def iso(val)
        s = val.to_s.strip
        return nil if s.empty? || s == "null"
        y, m, d = s.split("-").map(&:to_i)
        return format("%04d-%02d-%02d", y, (m > 0 ? m : 1), (d > 0 ? d : 1)) if y && y > 0
        nil
      rescue
        nil
      end

      def normalize_job(row)
        r = row.to_h.symbolize_keys
        {
          user_id:         @user.id,
          company_name:    r[:company_name] || r[:company],
          job_title:       r[:job_title]    || r[:title],
          started_on:      iso(r[:started_on]),
          ended_on:        iso(r[:ended_on]),
          current:         r.key?(:current) ? !!r[:current] : (r[:ended_on].blank?),
          location:        r[:location],
          job_description: r[:job_description] || r[:description],
          responsibilities: r[:responsibilities]
        }.compact
      end

      def normalize_experience(row)
        x = row.to_h.symbolize_keys
        {
          title:         x[:title],
          description:   x[:description],
          impact:        x[:impact],
          skills:        Array(x[:skills]).map(&:to_s).uniq,
          tools:         Array(x[:tools]).map(&:to_s).uniq,
          tags:          Array(x[:tags]).map(&:to_s).uniq,
          metrics:       x[:metrics].is_a?(Hash) ? x[:metrics] : {},
          started_on:    iso(x[:started_on]),
          ended_on:      iso(x[:ended_on]),
          order_index:   x[:order_index],
          reference_url: x[:reference_url]
        }.compact
      end

      # De-dup: (user_id, company_name, job_title, started_on)
      def upsert_employment_record(attrs)
        if @dry
          return [::EmploymentRecord.new(attrs) rescue nil, true]
        end

        rec = ::EmploymentRecord.where(
          user_id: attrs[:user_id],
          company_name: attrs[:company_name],
          job_title: attrs[:job_title],
          started_on: attrs[:started_on]
        ).first

        if rec
          rec.assign_attributes(attrs.except(:user_id, :company_name, :job_title, :started_on))
          rec.save! if rec.changed?
          [rec, false]
        else
          [::EmploymentRecord.create!(attrs), true]
        end
      end

      # De-dup: (employment_record_id, title, started_on)
      def upsert_experience(attrs)
        if @dry
          return [::EmploymentExperience.new(attrs) rescue nil, true]
        end

        finder = {
          employment_record_id: attrs[:employment_record_id],
          title: attrs[:title],
          started_on: attrs[:started_on]
        }
        rec = ::EmploymentExperience.where(finder).first

        if rec
          rec.assign_attributes(attrs.except(:employment_record_id, :title, :started_on))
          rec.save! if rec.changed?
          [rec, false]
        else
          [::EmploymentExperience.create!(attrs), true]
        end
      end
    end
  end
end
