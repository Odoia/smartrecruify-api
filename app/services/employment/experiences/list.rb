# frozen_string_literal: true

# app/services/employment/experiences/list.rb
module Employment
  module Experiences
    class List
      def initialize(employment_record:, filters: nil)
        @employment_record = employment_record
        @filters           = (filters || {}).to_h.symbolize_keys
      end

      # Retorna um ActiveRecord::Relation de EmploymentExperience
      def call
        scope = employment_record.employment_experiences
        f     = filters

        # title ILIKE %...%
        if f[:title].present?
          like  = "%#{ActiveRecord::Base.sanitize_sql_like(f[:title].to_s)}%"
          scope = scope.where("title ILIKE ?", like)
        end

        # started_on >= from
        if f[:started_on_from].present?
          from_date = parse_iso_date(f[:started_on_from])
          scope     = scope.where("started_on >= ?", from_date) if from_date
        end

        # started_on <= to
        if f[:started_on_to].present?
          to_date = parse_iso_date(f[:started_on_to])
          scope   = scope.where("started_on <= ?", to_date) if to_date
        end

        scope.order(:order_index, started_on: :desc, created_at: :desc)
      end

      private

      attr_reader :employment_record, :filters

      def parse_iso_date(value)
        Date.iso8601(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
