# frozen_string_literal: true

module Auth
  # app/controllers/auth/refresh_tokens_controller.rb
  class RefreshTokensController < ApplicationController
    before_action :authenticate_user!, only: [:destroy]

    def create
      Auth::RefreshHandle.new.rotate(request: request, response: response)
      render json: current_user.slice(:id, :email, :role)
    rescue StandardError => e
      Rails.logger.info("refresh rotate error: #{e.class}: #{e.message}")
      head :unauthorized  # <- Em vez de estourar 500
    end

    def destroy
      Auth::RefreshHandle.new.revoke(request: request, response: response)
      head :no_content
    rescue StandardError => e
      Rails.logger.info("refresh revoke error: #{e.class}: #{e.message}")
      head :no_content
    end

    private

    def handle
      @handle ||= Auth::RefreshHandle.new
    end
  end
end
