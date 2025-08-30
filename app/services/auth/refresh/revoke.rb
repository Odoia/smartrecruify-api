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
        raw = @cookie.read(request:)
        if raw.present?
          payload = Jwt.decode!(raw) rescue nil
          if payload && payload["jti"]
            @store.revoke!(jti: payload["jti"])
          end
        end
        @cookie.delete!(response:)
        true
      end
    end
  end
end
