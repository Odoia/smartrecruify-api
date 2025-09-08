# app/controllers/education/education_records_controller.rb
class Education::EducationRecordsController < ApplicationController
  before_action :authenticate_user!

  # Lists all formal education records for the current user's education profile.
  def index
    render json: education_profile.education_records.order(created_at: :desc)
  end

  # Creates a new formal education record (e.g., Bachelor in progress).
  def create
    record = Education::EducationRecords::Create.call(
      profile: education_profile,
      params: education_record_params
    )
    render json: record, status: :created
  end

  # Updates an existing formal education record.
  def update
    record = education_profile.education_records.find(params[:id])
    Education::EducationRecords::Update.call(record: record, params: education_record_params)
    render json: record
  end

  # Deletes a formal education record.
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
    params.require(:education_record).permit(
      :degree_level, :institution_name, :program_name,
      :started_on, :expected_end_on, :completed_on,
      :status, :gpa, :transcript_url
    )
  end
end
