# frozen_string_literal: true

require "jwt"
require "securerandom"

module Auth
  module Access
    # app/services/auth/access/jwt.rb
    class Jwt
      ALG = "HS256"

      def self.mint_for(user_id:)
        now = Time.now.to_i
        exp = now + ENV.fetch("ACCESS_TTL_SECONDS", "900").to_i # 15m default
        payload = {
          sub: user_id.to_s,
          iat: now,
          exp: exp,
          scp: "user",
          jti: SecureRandom.uuid,
          typ: "access"
        }
        JWT.encode(payload, secret, ALG)
      end

      def self.decode!(token)
        JWT.decode(token, secret, true, { algorithm: ALG }).first
      end

      def self.secret
        ENV.fetch("ACCESS_JWT_SECRET")
      end
    end
  end
end
