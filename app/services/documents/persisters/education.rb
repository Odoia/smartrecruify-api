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
        return ok(0) if @items.empty?

        ActiveRecord::Base.transaction do
          @items.each do |raw|
            n = normalize(raw)
            next unless minimally_valid?(n)

            record = ::Education.find_or_initialize_by(
              user_id:        @user_id,
              institution_name: n[:institution_name],
              course_name:      n[:course_name],
              start_date:       n[:start_date],
              end_date:         n[:end_date]
            )

            action = record.new_record? ? :created : :updated

            record.assign_attributes(
              course_acronym: n[:course_acronym],
              course_type:    n[:course_type],
              workload_hours: n[:workload_hours],
              in_progress:    n[:in_progress]
            )

            record.save!
            @results << { action:, id: record.id }
          end
        end

        ok(@results.size, @results)
      rescue => e
        { result: false, error: e.message }
      end

      private

      def normalize(raw)
        started_on      = parse_date(raw[:started_on] || raw["started_on"])
        ended_on        = parse_date(raw[:ended_on]   || raw["ended_on"])
        expected_end_on = parse_date(raw[:expected_end_on] || raw["expected_end_on"])
        status          = (raw[:status] || raw["status"]).to_s.downcase

        {
          institution_name: safe_str(raw[:institution_name] || raw["institution_name"]),
          course_acronym:   nil,
          course_name:      safe_str(raw[:program_name] || raw["program_name"]),
          course_type:      normalize_degree_level(raw[:degree_level] || raw["degree_level"]),
          start_date:       started_on,
          end_date:         ended_on,
          workload_hours:   nil,
          in_progress:      infer_in_progress(status:, ended_on:, expected_end_on:)
        }
      end

      def minimally_valid?(n)
        n[:institution_name].present? && n[:course_name].present? &&
          (n[:start_date].present? || n[:end_date].present?)
      end

      def infer_in_progress(status:, ended_on:, expected_end_on:)
        return false if status == "completed" || ended_on.present?
        return true  if %w[in_progress ongoing current studying].include?(status)
        expected_end_on.present?
      end

      def normalize_degree_level(v)
        s = v.to_s.downcase.strip
        return nil if s.empty?
        case s
        when "bachelor", "bacharel", "graduation", "grad" then "bachelor"
        when "technical", "técnico", "tecnico"            then "technical"
        when "online", "mooc"                              then "online"
        when "master", "mestrado"                          then "master"
        when "phd", "doutorado"                            then "phd"
        else s
        end
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
