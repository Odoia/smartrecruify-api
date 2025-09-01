# frozen_string_literal: true

module Auth
  # app/controllers/auth/refresh_tokens_controller.rb
  class RefreshTokensController < ApplicationController
    def create
      user = Auth::RefreshHandle.new.rotate(request: request, response: response)
      render json: user.slice(:id, :email, :role)
    rescue Auth::Refresh::Errors::InvalidToken
      render json: { error: "invalid refresh token" }, status: :unauthorized
    end

    def destroy
      Auth::RefreshHandle.new.revoke(request: request, response: response)
      head :no_content
    end
  end
end
