# frozen_string_literal: true

# app/services/auth/refresh/issue.rb
module Auth
  module Refresh
    class Issue
      def initialize(store:, cookie:)
        @store = store
        @cookie = cookie
      end

      def call(user:, response:)
        token, jti, exp = Jwt.mint_for(user_id: user.id)
        @store.put!(jti:, user_id: user.id, exp:)
        @cookie.write!(response:, value: token, exp:)
        token
      end
    end
  end
end
