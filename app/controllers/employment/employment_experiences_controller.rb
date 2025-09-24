# frozen_string_literal: true

module Employment
  # app/controllers/employment/experiences_controller.rb
  class EmploymentExperiencesController < ApplicationController
    before_action :authenticate_user!
    before_action :load_employment_record
    before_action :load_experience, only: [:update, :destroy]

    def index
      experiences = ::Employment::Experiences::List.new(
        employment_record: @employment_record
      ).call
      render json: experiences, status: :ok
    end

    def create
      exp = ::Employment::Experiences::Create.new(
        employment_record: @employment_record,
        params: experience_params
      ).call
      render json: exp, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "validation_failed", details: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def update
      exp = ::Employment::Experiences::Update.new(
        experience: @experience,
        params: experience_params
      ).call
      render json: exp, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "validation_failed", details: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def destroy
      ::Employment::Experiences::Destroy.new(experience: @experience).call
      head :no_content
    end

    private

    def load_employment_record
      id = params[:employment_record_id] || params[:id]
      @employment_record = ::Employment::Records::Find.new(
        user: current_user,
        id: id
      ).call
    end

    def load_experience
      @experience = ::Employment::Experiences::Find.new(
        employment_record: @employment_record,
        id: params[:id]
      ).call
    end

    def experience_params
      params.require(:employment_experience).permit(
        :title, :description, :impact,
        :started_on, :ended_on, :order_index, :reference_url,
        skills: [], tools: [], tags: [], metrics: {}
      )
    end
  end
end
