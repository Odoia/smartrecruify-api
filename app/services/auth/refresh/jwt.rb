# frozen_string_literal: true

require "jwt"

module Auth
  module Refresh
    # app/services/auth/refresh/jwt.rb
    class Jwt
      ALG = "HS256"

      def self.mint_for(user_id:)
        now = Time.now.to_i
        ttl = ENV.fetch("REFRESH_TTL_SECONDS", "2592000").to_i
        exp = now + ttl
        jti = SecureRandom.uuid
        payload = { sub: user_id.to_s, jti:, iat: now, exp:, typ: "refresh" }
        token = JWT.encode(payload, secret, ALG)
        [token, jti, exp]
      end

      def self.decode!(token)
        decoded, = JWT.decode(token, secret, true, { algorithm: ALG })
        decoded
      end

      def self.secret
        ENV.fetch("REFRESH_JWT_SECRET")
      end
    end
  end
end
