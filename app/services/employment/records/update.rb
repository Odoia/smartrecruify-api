# frozen_string_literal: true

module Employment
  module Records
    class Update
      def initialize(record:, params:)
        @record = record
        @params = params || {}
      end

      def call
        @record.update!(@params)
        @record
      end
    end
  end
end
