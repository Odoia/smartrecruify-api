# frozen_string_literal: true

module Auth
  module Refresh
    # app/services/auth/refresh/rotate.rb
    class Rotate
      def initialize(store:, cookie:)
        @store  = store
        @cookie = cookie
      end

      def call(request:, response:)
        raw = @cookie.read_from(request)
        raise Errors::InvalidToken if raw.blank?

        payload = Jwt.decode!(raw)
        sub, jti, exp = payload.values_at("sub", "jti", "exp")
        raise Errors::InvalidToken if [sub, jti, exp].any?(&:nil?)
        raise Errors::InvalidToken unless @store.valid_for_rotation?(payload)

        new_token, new_jti, new_exp = Jwt.mint_for(user_id: sub.to_i)
        if @store.respond_to?(:rotate!)
          @store.rotate!(payload, new_jti: new_jti, new_exp: new_exp)
        else
          @store.delete!(payload)
          @store.put!({ "jti" => new_jti, "sub" => sub, "exp" => new_exp })
        end

        @cookie.write_to(response, new_token, expires_at: Time.at(new_exp))

        access = Auth::Access::Jwt.mint_for(user_id: sub.to_i)
        response.set_header("Authorization", "Bearer #{access}")

        User.find(sub.to_i)
      rescue JWT::DecodeError
        raise Errors::InvalidToken
      end
    end
  end
end
