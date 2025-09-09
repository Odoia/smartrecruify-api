# frozen_string_literal: true

module Employment
  # app/controllers/employment/employment_records_controller.rb
  class EmploymentRecordsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_employment_record, only: [:update, :destroy]

    def index
      records = current_user.employment_records
                            .order(current: :desc, started_on: :desc, created_at: :desc)
      render json: records
    end

    def create
      record = current_user.employment_records.new(employment_record_params)
      if record.save
        render json: record, status: :created
      else
        render json: { error: "validation_failed", details: record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @employment_record.update(employment_record_params)
        render json: @employment_record
      else
        render json: { error: "validation_failed", details: @employment_record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @employment_record.destroy!
      head :no_content
    end

    private

    def set_employment_record
      @employment_record = current_user.employment_records.find(params[:id])
    end

    def employment_record_params
      params.require(:employment_record).permit(
        :company_name,
        :job_title,
        :started_on,
        :ended_on,
        :current,
        :job_description,
        :responsibilities
      )
    end
  end
end
