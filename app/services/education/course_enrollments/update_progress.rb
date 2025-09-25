# frozen_string_literal: true

# app/services/education/course_enrollments/update_progress.rb
module Education
  module CourseEnrollments
    class UpdateProgress
      def initialize(enrollment:, attrs:)
        @enrollment = enrollment
        @attrs      = attrs
      end

      def call
        enrollment.update!(attrs)
        enrollment
      end

      private

      attr_reader :enrollment, :attrs
    end
  end
end
