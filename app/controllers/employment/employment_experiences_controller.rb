# frozen_string_literal: true

# app/controllers/employment/experiences_controller.rb
module Employment
  class EmploymentExperiencesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_employment_record
    before_action :set_experience, only: [:update, :destroy]

    def index
      experiences = @employment_record.employment_experiences
                                      .order(:order_index, started_on: :desc, created_at: :desc)
      render json: experiences
    end

    def create
      exp = @employment_record.employment_experiences.new(experience_params)
      if exp.save
        render json: exp, status: :created
      else
        render json: { error: "validation_failed", details: exp.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @experience.update(experience_params)
        render json: @experience
      else
        render json: { error: "validation_failed", details: @experience.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @experience.destroy!
      head :no_content
    end

    private

    def set_employment_record
      @employment_record = current_user.employment_records.find(params[:employment_record_id])
    end

    def set_experience
      @experience = @employment_record.employment_experiences.find(params[:id])
    end

    def experience_params
      params.require(:employment_experience).permit(
        :title,
        :description,
        :impact,
        :started_on,
        :ended_on,
        :order_index,
        :reference_url,
        skills: [],
        tools:  [],
        tags:   [],
        metrics: {}
      )
    end
  end
end
