# frozen_string_literal: true

module Auth
  module Refresh
    # app/services/auth/refresh/cookie.rb
    class Cookie
      NAME = "refresh_token"
      PATH = "/auth/refresh"

      def read_from(request)
        request&.cookies&.[](NAME)
      end
      alias_method :read, :read_from

      def write_to(response, token, expires_at:)
        response.set_cookie(
          NAME,
          value:     token,
          path:      PATH,
          httponly:  true,
          same_site: :lax,
          secure:    Rails.env.production?,
          expires:   expires_at
        )
      end
      def write(response, token, expires_at:)
        write_to(response, token, expires_at: expires_at)
      end

      def delete_from(response)
        response.delete_cookie(
          NAME,
          path:      PATH,
          same_site: :lax,
          secure:    Rails.env.production?
        )
      end
      alias_method :delete, :delete_from
    end
  end
end
