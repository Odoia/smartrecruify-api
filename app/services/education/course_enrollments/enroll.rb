# app/services/education/course_enrollments/enroll.rb
module Education
  module CourseEnrollments
    class Enroll
      # Enrolls a profile in a catalog course, optionally as in_progress
      def self.call(profile:, course:, params: {})
        enrollment = profile.course_enrollments.new({ course: course }.merge(params))
        enrollment.save!
        enrollment
      end
    end
  end
end
