# frozen_string_literal: true

module Documents
  module Persisters
    class Education
      def self.call(user_id:, items:)
        new(user_id:, items:).call
      end

      def initialize(user_id:, items:)
        @user_id = user_id
        @items   = Array(items)
        @results = []
      end

      def call
        Rails.logger.info("[PERSISTERS::EDUCATION] user=#{@user_id} items=#{@items.size}")
        return ok(0) if @items.empty?

        profile = find_or_create_profile!(@user_id)

        ActiveRecord::Base.transaction do
          @items.each do |raw|
            n = normalize(raw) # mantém shape do payload, convertendo datas p/ Date
            Rails.logger.info("[PERSISTERS::EDUCATION] normalized=#{n.inspect}")

            # Idempotência: 1 registro por (instituição + programa + início + fim)
            record = ::EducationRecord.find_or_initialize_by(
              education_profile_id: profile.id,
              institution_name: n[:institution_name],
              program_name:     n[:program_name],
              started_on:       n[:started_on],
              ended_on:         n[:ended_on]
            )

            action = record.new_record? ? :created : :updated

            # Atribui apenas colunas existentes no modelo para evitar NoMethodError
            assign_attrs(record, n)

            record.save!
            Rails.logger.info("[PERSISTERS::EDUCATION] #{action} id=#{record.id}")
            @results << { action:, id: record.id }
          end
        end

        ok(@results.size, @results)
      rescue => e
        Rails.logger.error("[PERSISTERS::EDUCATION] ERROR #{e.class}: #{e.message}")
        { result: false, error: e.message }
      end

      private

      def find_or_create_profile!(user_id)
        ::EducationProfile.find_or_create_by!(user_id: user_id)
      end

      # Mantém nomes do teu payload: institution_name, degree_level, program_name, started_on, expected_end_on, ended_on, status, gpa, transcript_url
      def normalize(raw)
        {
          institution_name: safe_str(raw[:institution_name] || raw["institution_name"]),
          degree_level:     safe_str(raw[:degree_level]     || raw["degree_level"]),
          program_name:     safe_str(raw[:program_name]     || raw["program_name"]),
          started_on:       parse_date(raw[:started_on]     || raw["started_on"]),
          expected_end_on:  parse_date(raw[:expected_end_on]|| raw["expected_end_on"]),
          ended_on:         parse_date(raw[:ended_on]       || raw["ended_on"]),
          status:           (raw[:status] || raw["status"]).to_s.presence,
          gpa:              raw[:gpa] || raw["gpa"],
          transcript_url:   safe_str(raw[:transcript_url]   || raw["transcript_url"])
        }
      end

      def assign_attrs(record, attrs_hash)
        allowed = record.attribute_names.map!(&:to_sym)
        record.assign_attributes(attrs_hash.slice(*allowed))
      end

      def parse_date(v)
        return nil if v.nil? || v.to_s.strip.empty?
        v.is_a?(Date) ? v : Date.parse(v.to_s) rescue nil
      end

      def safe_str(v)
        s = v.to_s.strip
        s.empty? ? nil : s
      end

      def ok(count, items = [])
        { result: true, count:, items: }
      end
    end
  end
end
