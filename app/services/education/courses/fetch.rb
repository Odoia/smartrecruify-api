# frozen_string_literal: true

module Education
  module Courses
    class Fetch
      def initialize(id:)
        @id = id
      end

      def call
        ::Course.find(id)
      end

      private

      attr_reader :id
    end
  end
end
