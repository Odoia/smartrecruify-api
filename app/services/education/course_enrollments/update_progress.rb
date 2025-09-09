# app/services/education/course_enrollments/update_progress.rb
module Education
  module CourseEnrollments
    class UpdateProgress
      # Updates status/progress/dates of an enrollment
      def self.call(enrollment:, params:)
        enrollment.update!(params)
        enrollment
      end
    end
  end
end
