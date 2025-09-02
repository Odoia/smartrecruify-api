# frozen_string_literal: true

module Auth
  # app/controllers/auth/sessions_controller.rb
  class SessionsController < ApplicationController
    def sign_up
      user = User.new(sign_up_params)
      if user.save
        render json: { id: user.id, email: user.email, name: user.name, role: user.role }, status: :created
      else
        render json: { error: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def create
      user = User.find_by(email: params.dig(:session, :email) || params[:email])
      unless user&.valid_password?(params.dig(:session, :password) || params[:password])
        return head :unauthorized
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
      render json: user.slice(:id, :email, :name, :role)
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
      params.permit(:email, :password, :name, :locale, :timezone)
    end
  end
end
