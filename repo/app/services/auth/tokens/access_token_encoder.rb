# # frozen_string_literal: true

# app/services/auth/tokens/access_token_encoder.rb
module Auth
  module Tokens
    class AccessTokenEncoder
      def self.call(user)
        Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
      end
    end
  end
end
