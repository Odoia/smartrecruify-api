# frozen_string_literal: true

module Auth
  module Refresh
    # app/services/auth/refresh/revoke.rb
    class Revoke
      def initialize(store:, cookie:)
        @store  = store
        @cookie = cookie
      end

      def call(request:, response:)
        raw = @cookie.read_from(request)
        if raw.present?
          begin
            payload = Jwt.decode!(raw)
            @store.delete!(payload)
          rescue JWT::DecodeError
          end
        end
        @cookie.delete_from(response)
        true
      end
    end
  end
end
