# frozen_string_literal: true

# app/services/education/course_enrollments/enroll.rb
module Education
  module CourseEnrollments
    class Enroll
      def self.call(profile:, course_id:, attrs: {})
        raise ArgumentError, "profile is required"   unless profile.present?
        raise ArgumentError, "course_id is required" unless course_id.present?

        course = ::Course.find(course_id)

        permitted_attrs = pick_permitted_attrs(attrs)

        enrollment = profile.course_enrollments.find_or_initialize_by(course_id: course.id)
        enrollment.assign_attributes(permitted_attrs)
        enrollment.save!
        enrollment
      end

      PERMITTED_KEYS = %i[
        status
        started_on
        expected_end_on
        completed_on
        progress_percent
      ].freeze
      private_constant :PERMITTED_KEYS

      def self.pick_permitted_attrs(attrs)
        return {} unless attrs.is_a?(Hash)
        attrs.symbolize_keys.slice(*PERMITTED_KEYS)
      end
      private_class_method :pick_permitted_attrs
    end
  end
end
