# frozen_string_literal: true

module Education
  module CourseEnrollments
    class List
      def initialize(profile:, filters: {})
        @profile = profile
        @filters = filters || {}
      end

      def call
        scope = profile.course_enrollments.includes(:course)

        if filters[:status].present?
          scope = scope.where(status: filters[:status])
        end

        if filters[:course_id].present?
          scope = scope.where(course_id: filters[:course_id])
        end

        if filters[:started_on_from].present?
          scope = scope.where("started_on >= ?", filters[:started_on_from])
        end

        if filters[:started_on_to].present?
          scope = scope.where("started_on <= ?", filters[:started_on_to])
        end

        scope.order(created_at: :desc)
      end

      private

      attr_reader :profile, :filters
    end
  end
end
