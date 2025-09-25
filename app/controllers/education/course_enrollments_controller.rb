# frozen_string_literal: true

# app/controllers/education/course_enrollments_controller.rb
class Education::CourseEnrollmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    enrollments = Education::CourseEnrollments::List
      .new(profile: education_profile, filters: filter_params.to_h.symbolize_keys)
      .call

    render json: enrollments, status: :ok
  end

  def create
    attrs     = enrollment_params.to_h.symbolize_keys
    course_id = attrs.delete(:course_id)

    enrollment = Education::CourseEnrollments::Enroll.call(
      profile:   education_profile,
      course_id: course_id,
      attrs:     attrs
    )

    render json: enrollment, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "course_not_found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_failed", details: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def update
    enrollment = education_profile.course_enrollments.find(params[:id])

    Education::CourseEnrollments::UpdateProgress
      .new(enrollment: enrollment, attrs: enrollment_update_params) # <-- aqui
      .call

    render json: enrollment, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "enrollment_not_found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "validation_failed", details: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def destroy
    enrollment = education_profile.course_enrollments.find(params[:id])
    enrollment.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "enrollment_not_found" }, status: :not_found
  end

  private

  def education_profile
    @education_profile ||= current_user.education_profile || current_user.create_education_profile!
  end

  def enrollment_params
    params
      .require(:course_enrollment)
      .permit(:course_id, :status, :started_on, :expected_end_on, :completed_on, :progress_percent)
  end

  def enrollment_update_params
    params
      .require(:course_enrollment)
      .permit(:status, :started_on, :expected_end_on, :completed_on, :progress_percent)
      .to_h
      .symbolize_keys
  end

  def filter_params
    params
      .fetch(:filter, {})
      .permit(:status, :course_id, :started_on_from, :started_on_to)
  end
end
