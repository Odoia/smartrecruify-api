# frozen_string_literal: true

module Auth
  module Refresh
    # app/services/auth/refresh/cookie.rb
    class Cookie
      NAME      = "refresh_token"
      PATH      = "/auth/refresh"
      SAME_SITE = :lax 
      SECURE    = Rails.env.production?
      HTTPONLY  = true

      def write!(response:, value:, exp:)
        response.set_cookie(
          NAME,
          value:   value,
          httponly: HTTPONLY,
          same_site: SAME_SITE,
          secure:  SECURE,
          path:    PATH,
          expires: Time.at(exp)
        )
      end

      def read(request:)
        request.cookies[NAME]
      end

      def delete!(response:)
        response.delete_cookie(NAME, path: PATH)
      end
    end
  end
end
