# frozen_string_literal: true

module Employment
  module Records
    class Create
      def initialize(user:, params:)
        @user   = user
        @params = params || {}
      end

      def call
        record = @user.employment_records.new(@params)
        record.save!
        record
      end
    end
  end
end
