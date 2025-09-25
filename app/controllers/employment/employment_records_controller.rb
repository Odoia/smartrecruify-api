# frozen_string_literal: true

module Employment
  # app/controllers/employment/employment_records_controller.rb
  class EmploymentRecordsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_employment_record, only: [:update, :destroy]

    def index
      records = ::Employment::Records::List.new(user: current_user).call
      render json: records, status: :ok
    end

    def create
      record = ::Employment::Records::Create.new(
        user: current_user,
        params: employment_record_params.to_h
      ).call

      render json: record, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "validation_failed", details: e.record.errors.full_messages },
             status: :unprocessable_entity
    end

    def update
      record = ::Employment::Records::Update.new(
        record: @employment_record,
        params: employment_record_params.to_h
      ).call

      render json: record, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "validation_failed", details: e.record.errors.full_messages },
             status: :unprocessable_entity
    end

    def destroy
      ::Employment::Records::Destroy.new(record: @employment_record).call
      head :no_content
    end

    private

    def load_employment_record
      record_id = params[:employment_record_id] || params[:id]
      @employment_record = ::Employment::Records::Find.new(
        user: current_user,
        id: record_id
      ).call
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
