# frozen_string_literal: true

require "jwt"

module Auth
  module AccessGuard
    def current_user
      return @current_user if defined?(@current_user)

      token = extract_bearer_token_from_request(request)
      Rails.logger.info("ACCESS_GUARD auth headers -> HTTP_AUTHORIZATION=#{request.env['HTTP_AUTHORIZATION']} | Authorization=#{request.headers['Authorization']} | request.authorization=#{request.authorization}")
      Rails.logger.info("ACCESS_GUARD extracted token present? #{token.present?}")

      if token.present?
        begin
          payload = Auth::Access::Jwt.decode!(token)
          Rails.logger.info("ACCESS_GUARD decoded payload=#{payload.inspect}")

          access_store = Auth::Tokens::Adapters::AccessStoreRedis.new
          unless access_store.exists?(payload)
            Rails.logger.info("ACCESS_GUARD access jti ausente no Redis -> revogado")
            @current_user = nil
            return @current_user
          end

          uid = payload["sub"]
          if uid
            @current_user = User.find_by(id: uid)
            Rails.logger.info("ACCESS_GUARD current_user.id=#{@current_user&.id}")
            return @current_user
          end
        rescue JWT::DecodeError => e
          Rails.logger.info("ACCESS_GUARD decode error: #{e.class}: #{e.message}")
        end
      end

      @current_user = nil
    end

    def authenticate_user!
      head :unauthorized and return unless current_user
    end

    private

    def extract_bearer_token_from_request(req)
      header = req.headers["Authorization"] || req.env["HTTP_AUTHORIZATION"] || req.authorization
      return nil unless header&.start_with?("Bearer ")
      header.split(" ", 2).last
    end
  end
end
