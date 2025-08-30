# frozen_string_literal: true

module Auth
  # app/controllers/auth/refresh_tokens_controller.rb
  class RefreshTokensController < ApplicationController
    before_action :authenticate_user!, only: [:destroy]

    def create
      result = RefreshHandle.new.rotate(request: request, response: response)
      response.set_header("Authorization", "Bearer #{result.jwt}")
      render json: { id: result.user.id, email: result.user.email, role: result.user.role }, status: :ok
    end

    def destroy
      RefreshHandle.new.revoke(request: request, response: response)
      head :no_content
    end

    private

    def handle
      @handle ||= Auth::RefreshHandle.new
    end
  end
end
