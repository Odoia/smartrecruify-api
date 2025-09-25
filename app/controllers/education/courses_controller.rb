# frozen_string_literal: true

# app/controllers/education/courses_controller.rb
class Education::CoursesController < ApplicationController
  before_action :authenticate_user!

  def index
    result = Education::Courses::List.new(
      filters: index_filters
    ).call

    render json: result, status: :ok
  end

  def show
    course = Education::Courses::Fetch.new(id: params[:id]).call
    render json: course, status: :ok
  end

  private

  def index_filters
    {
      search:   params[:search].to_s.strip.presence,
      category: params[:category].presence,
      page:     (params[:page].presence || 1).to_i
    }
  end
end
