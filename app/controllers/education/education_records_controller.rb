# frozen_string_literal: true

# app/controllers/education/education_records_controller.rb
class Education::EducationRecordsController < ApplicationController
  before_action :authenticate_user!

  def index
    records = Education::EducationRecords::List.new(
      profile: education_profile,
      filters: filter_params.to_h.symbolize_keys
    ).call

    render json: records, status: :ok
  end

  def create
    record = Education::EducationRecords::Create.call(
      profile: education_profile,
      params: education_record_params
    )
    render json: record, status: :created
  end

  def update
    record = education_profile.education_records.find(params[:id])

    Education::EducationRecords::Update.call(
      record: record,
      params: education_record_params
    )

    render json: record, status: :ok
  end

  def destroy
    record = education_profile.education_records.find(params[:id])
    Education::EducationRecords::Destroy.call(record: record)
    head :no_content
  end

  private

  def education_profile
    @education_profile ||= current_user.education_profile || current_user.create_education_profile!
  end

  def education_record_params
    params
      .require(:education_record)
      .permit(
        :degree_level,
        :institution_name,
        :program_name,
        :started_on,
        :expected_end_on,
        :completed_on,
        :status,
        :gpa,
        :transcript_url
      )
  end

  def filter_params
    params
      .fetch(:filter, {})
      .permit(:status, :institution_name, :degree_level)
  end
end
