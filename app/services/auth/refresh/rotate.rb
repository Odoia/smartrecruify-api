# frozen_string_literal: true

module Auth
  module Refresh
    # app/services/auth/refresh/rotate.rb
    class Rotate
      Result = Struct.new(:jwt, :user, keyword_init: true)

      def initialize(store:, cookie:)
        @store  = store
        @cookie = cookie
      end

      def call(request:, response:)
        raw = @cookie.read(request:)
        raise "Invalid refresh token" if raw.blank?

        payload = Jwt.decode!(raw)
        raise "Invalid refresh type" unless payload["typ"] == "refresh"

        jti     = payload.fetch("jti")
        user_id = @store.fetch_user_id(jti:)
        raise "Revoked or unknown refresh" if user_id.blank?

        @store.revoke!(jti:)

        new_token, new_jti, new_exp = Jwt.mint_for(user_id:)
        @store.put!(jti: new_jti, user_id:, exp: new_exp)
        @cookie.write!(response:, value: new_token, exp: new_exp)

        user = User.find(user_id)
        access_jwt, _ = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

        Result.new(jwt: access_jwt, user:)
      end
    end
  end
end
