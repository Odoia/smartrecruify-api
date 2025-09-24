# frozen_string_literal: true

# app/services/education/course_enrollments/list.rb
module Education
  module CourseEnrollments
    class List
      def initialize(limit: 50)
        @limit = limit
      end

      def call
        Course
          .order(Arel.sql("LOWER(provider), LOWER(name)"))
          .limit(@limit)
          .pluck(:provider, :name)
          .map { |provider, name| { provider:, name: } }
      end

      private

      attr_reader :limit
    end
  end
end
