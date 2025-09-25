# frozen_string_literal: true

module Documents
  module Persisters
    class Handler
      def initialize(user_id:, payload:)
        @user_id = user_id
        @payload = payload || {}
      end

      def call
        results = {}

        ActiveRecord::Base.transaction do
          results[:education]  = Education.new(user_id: user_id, items: @payload["education_records"]).call
          results[:employment] = Employment.new(user_id: user_id, items: @payload["employment"]).call
        end

        { ok: true, results: results }
      rescue => e
        { ok: false, error: e.message }
      end

      private

      attr_reader :user_id
    end
  end
end
