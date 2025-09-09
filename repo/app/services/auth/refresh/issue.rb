# frozen_string_literal: true

module Auth
  module Refresh
    # app/services/auth/refresh/issue.rb
    class Issue
      def initialize(store:, cookie:)
        @store  = store
        @cookie = cookie
      end

      def call(user:, response:)
        token, jti, exp = Jwt.mint_for(user_id: user.id)
        @store.put!({ "jti" => jti, "sub" => user.id.to_s, "exp" => exp })
        @cookie.write_to(response, token, expires_at: Time.at(exp))
        true
      end
    end
  end
end
