# frozen_string_literal: true
class MeController < ApplicationController
  before_action :authenticate_user!

  def show
    Rails.logger.info("ME#show current_user.id=#{current_user&.id}")
    render json: current_user.slice(:id, :email, :name, :role)
  end
end
