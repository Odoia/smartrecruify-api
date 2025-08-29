# app/controllers/me_controller.rb
class MeController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: { id: current_user.id, email: current_user.email, name: current_user.name, role: current_user.role }
  end
end
