# frozen_string_literal: true

module Auth
  # app/controllers/auth/sessions_controller.rb
  class SessionsController < ApplicationController
    def sign_up
      attrs = sign_up_params
      user  = User.new(attrs)

      if user.save
        render json: { user: user.slice(:id, :email, :name, :role) }, status: :created
      else
        render json: { error: "validation_failed", details: user.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render json: { error: "invalid_payload", hint: "expected { auth: { email, password, ... } }" }, status: :bad_request
    end

    def create
      creds = sign_in_params

      email    = creds[:email].to_s.strip.downcase
      password = creds[:password].to_s

      if email.blank? || password.blank?
        return render json: { error: "invalid_credentials" }, status: :unauthorized
      end

      user = User.find_by("LOWER(email) = ?", email)

      unless user&.valid_password?(password)
        Rails.logger.info("[SIGN IN] invalid credentials for email=#{email.inspect}") if Rails.env.development?
        return render json: { error: "invalid_credentials" }, status: :unauthorized
      end

      access = Auth::Access::Jwt.mint_for(user_id: user.id)
      response.set_header("Authorization", "Bearer #{access}")

      begin
        access_payload = Auth::Access::Jwt.decode!(access)
        Auth::Tokens::Adapters::AccessStoreRedis.new.put!(access_payload)
      rescue => e
        Rails.logger.warn("sign in access-store error: #{e.class}: #{e.message}")
      end

      Auth::RefreshHandle.new.issue_for(user: user, response: response)

      render json: { user: user.slice(:id, :email, :name, :role) }, status: :ok
    rescue ActionController::ParameterMissing
      render json: { error: "invalid_payload", hint: "expected { auth: { email, password } }" }, status: :bad_request
    rescue => e
      Rails.logger.info("sign in error: #{e.class}: #{e.message}")
      head :internal_server_error
    end

    def destroy
      token = request.headers["Authorization"]&.split(" ", 2)&.last
      if token.present?
        begin
          payload = Auth::Access::Jwt.decode!(token)
          Auth::Tokens::Adapters::AccessStoreRedis.new.delete!(payload)
        rescue JWT::DecodeError
        end
      end

      head :no_content
    end

    private

    def sign_up_params
      params.require(:auth).permit(:email, :password, :name, :locale, :timezone)
    end

    def sign_in_params
      params.require(:auth).permit(:email, :password)
    end
  end
end
