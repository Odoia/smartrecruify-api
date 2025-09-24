# frozen_string_literal: true

module Employment
  module Records
    class List
      def initialize(user:)
        @user = user
      end

      def call
        @user.employment_records
             .order(current: :desc)
             .order(started_on: :desc)
             .order(created_at: :desc)
      end
    end
  end
end
