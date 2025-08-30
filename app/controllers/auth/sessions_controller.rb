# frozen_string_literal: true

module Auth
  # app/controllers/auth/sessions_controller.rb
  class Auth::SessionsController < ApplicationController
    def sign_up
      user = User.new(sign_up_params)
      if user.save
        render json: { id: user.id, email: user.email, name: user.name, role: user.role }, status: :created
      else
        render json: { error: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def create
      user = User.find_for_database_authentication(email: params[:email])
      return render json: { error: "invalid_credentials" }, status: :unauthorized unless user&.valid_password?(params[:password])

      # Access token curto (header Authorization)
      access_jwt, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      response.set_header("Authorization", "Bearer #{access_jwt}")

      # Emite refresh cookie
      RefreshHandle.new.issue_for(user: user, response: response)

      render json: { id: user.id, email: user.email, name: user.name, role: user.role }, status: :ok
    end

    def destroy
      sign_out(current_user) if current_user
      head :no_content
    end

    private

    def sign_up_params
      params.permit(:email, :password, :name, :locale, :timezone)
    end
  end
end
