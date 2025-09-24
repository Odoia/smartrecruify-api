# frozen_string_literal: true

module Employment
  module Records
    class Find
      def initialize(user:, id:)
        @user = user
        @id   = id
      end

      def call
        @user.employment_records.find(@id)
      end
    end
  end
end
