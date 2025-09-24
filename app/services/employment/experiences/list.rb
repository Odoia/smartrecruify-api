# frozen_string_literal: true

module Employment
  module Experiences
    class List
      def initialize(employment_record:)
        @employment_record = employment_record
      end

      def call
        @employment_record.employment_experiences
                          .order(:order_index)
                          .order(started_on: :desc)
                          .order(created_at: :desc)
      end
    end
  end
end
