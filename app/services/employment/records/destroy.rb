# frozen_string_literal: true

module Employment
  module Records
    class Destroy
      def initialize(record:)
        @record = record
      end

      def call
        @record.destroy!
        { ok: true }
      end
    end
  end
end
