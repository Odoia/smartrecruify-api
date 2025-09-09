# app/controllers/education/language_skills_controller.rb
class Education::LanguageSkillsController < ApplicationController
  before_action :authenticate_user!

  # Lists all language skills for the current user's education profile.
  def index
    render json: education_profile.language_skills.order(language: :asc)
  end

  # Creates or updates (upsert) a language skill for the profile.
  def create
    skill = Education::LanguageSkills::Upsert.call(
      profile: education_profile,
      language: params.require(:language_skill)[:language],
      level: params.require(:language_skill)[:level],
      attrs: language_skill_params.except(:language, :level)
    )
    render json: skill, status: :created
  end

  # Updates a specific language skill (by id).
  def update
    skill = education_profile.language_skills.find(params[:id])
    skill.update!(language_skill_params)
    render json: skill
  end

  # Deletes a language skill.
  def destroy
    skill = education_profile.language_skills.find(params[:id])
    skill.destroy!
    head :no_content
  end

  private

  def education_profile
    @education_profile ||= current_user.education_profile || current_user.create_education_profile!
  end

  def language_skill_params
    params.require(:language_skill).permit(:language, :level, :certificate_name, :certificate_score)
  end
end
