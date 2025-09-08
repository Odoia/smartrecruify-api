# app/controllers/education/course_enrollments_controller.rb
class Education::CourseEnrollmentsController < ApplicationController
  before_action :authenticate_user!

  # Lists all course enrollments for the current user's education profile.
  def index
    render json: education_profile.course_enrollments.includes(:course).order(created_at: :desc).as_json(include: :course)
  end

  # Enrolls into a course (status defaults to enrolled or in_progress per params).
  def create
    course = Course.find(params.require(:course_id))
    enrollment = Education::CourseEnrollments::Enroll.call(
      profile: education_profile,
      course: course,
      params: enrollment_params
    )
    render json: enrollment, status: :created
  end

  # Updates progress/status/dates for an enrollment.
  def update
    enrollment = education_profile.course_enrollments.find(params[:id])
    Education::CourseEnrollments::UpdateProgress.call(enrollment: enrollment, params: enrollment_params)
    render json: enrollment
  end

  # Removes an enrollment.
  def destroy
    enrollment = education_profile.course_enrollments.find(params[:id])
    enrollment.destroy!
    head :no_content
  end

  private

  def education_profile
    @education_profile ||= current_user.education_profile || current_user.create_education_profile!
  end

  def enrollment_params
    params.require(:course_enrollment).permit(
      :status, :started_on, :expected_end_on, :completed_on, :progress_percent
    )
  end
end
