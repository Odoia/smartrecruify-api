# frozen_string_literal: true

module Employment
  module Experiences
    class Create
      def initialize(employment_record:, params:)
        @employment_record = employment_record
        @params = params || {}
      end

      def call
        exp = @employment_record.employment_experiences.new(@params)
        exp.save!
        exp
      end
    end
  end
end
