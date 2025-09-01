# frozen_string_literal: true
module Auth
  module AccessGuard
    def current_user
      return @current_user if defined?(@current_user)

      # Tente pelas três formas
      raw1 = request.get_header("HTTP_AUTHORIZATION")
      raw2 = request.headers["Authorization"]
      raw3 = request.authorization

      Rails.logger.info("ACCESS_GUARD auth headers -> HTTP_AUTHORIZATION=#{raw1.inspect} | Authorization=#{raw2.inspect} | request.authorization=#{raw3.inspect}")

      auth = raw1.presence || raw2.presence || raw3.presence || ""
      token = auth.start_with?("Bearer ") ? auth.split(" ", 2).last : nil

      Rails.logger.info("ACCESS_GUARD extracted token present? #{token.present?}")

      return @current_user = nil if token.blank?

      payload = Auth::Access::Jwt.decode!(token)
      Rails.logger.info("ACCESS_GUARD decoded payload=#{payload.inspect}")

      @current_user = User.find_by(id: payload["sub"])
      Rails.logger.info("ACCESS_GUARD current_user.id=#{@current_user&.id}")
      @current_user
    rescue => e
      Rails.logger.warn("ACCESS_GUARD decode error: #{e.class}: #{e.message}")
      @current_user = nil
    end

    def authenticate_access!
      head :unauthorized and return unless current_user
    end
  end
end
