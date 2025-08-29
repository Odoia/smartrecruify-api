# frozen_string_literal: true

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
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    return render json: { error: "Invalid credentials" }, status: :unauthorized unless user&.valid_password?(params[:password])

    sign_in(user, store: false)
    render json: { id: user.id, email: user.email, name: user.name, role: user.role }
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
