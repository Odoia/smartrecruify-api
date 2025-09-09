# app/services/education/course_enrollments/complete.rb
module Education
  module CourseEnrollments
    class Complete
      # Marks an enrollment as completed and sets completed_on today if missing
      def self.call(enrollment:, completed_on: Date.current)
        enrollment.update!(status: :completed, completed_on: (enrollment.completed_on || completed_on), progress_percent: 100)
        enrollment
      end
    end
  end
end
