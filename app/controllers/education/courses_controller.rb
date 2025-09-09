# app/controllers/education/courses_controller.rb
class Education::CoursesController < ApplicationController
  before_action :authenticate_user!

  # Lists catalog courses (can be filtered by category, text, etc.)
  def index
    scope = Course.all
    scope = scope.where(category: params[:category]) if params[:category].present?
    scope = scope.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
    render json: scope.order(:name).limit(200)
  end

  # Shows a single course from the catalog.
  def show
    render json: Course.find(params[:id])
  end
end
