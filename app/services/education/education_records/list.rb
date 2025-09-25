# frozen_string_literal: true

module Education
  module EducationRecords
    class List
      def initialize(profile:, filters: {})
        @profile = profile
        @filters = (filters || {}).symbolize_keys
      end

      def call
        scope = profile.education_records

        scope = scope.where(status: filters[:status])                 if present?(filters[:status])
        scope = scope.where(degree_level: filters[:degree_level])     if present?(filters[:degree_level])
        scope = scope.where("started_on >= ?", filters[:started_on_from]) if present?(filters[:started_on_from])
        scope = scope.where("started_on <= ?", filters[:started_on_to])   if present?(filters[:started_on_to])

        scope.order(created_at: :desc)
      end

      private

      attr_reader :profile, :filters

      def present?(value)
        value.respond_to?(:present?) ? value.present? : ![nil, ""].include?(value)
      end
    end
  end
end
