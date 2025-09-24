# frozen_string_literal: true

module Employment
  module Experiences
    class Find
      def initialize(employment_record:, id:)
        @employment_record = employment_record
        @id = id
      end

      def call
        @employment_record.employment_experiences.find(@id)
      end
    end
  end
end
