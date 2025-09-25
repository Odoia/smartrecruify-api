# frozen_string_literal: true

module Education
  # app/controllers/education/language_skills_controller.rb
  class LanguageSkillsController < ApplicationController
    before_action :authenticate_user!

    def index
      profile = load_profile
      skills  = Education::LanguageSkills::List.new(profile: profile).call
      render json: skills
    end

    def create
      profile = load_profile
      payload = params.require(:language_skill).permit(:language, :level, :certificate_name, :certificate_score)

      skill = Education::LanguageSkills::Upsert.new(
        profile: profile,
        language: payload[:language],
        level: payload[:level],
        attrs: payload.except(:language, :level)
      ).call

      render json: skill, status: :created
    end

    def update
      profile = load_profile
      payload = params.require(:language_skill).permit(:language, :level, :certificate_name, :certificate_score)

      skill = Education::LanguageSkills::Update.new(
        profile: profile,
        id: params[:id],
        attrs: payload
      ).call

      render json: skill
    end

    def destroy
      profile = load_profile

      Education::LanguageSkills::Destroy.new(
        profile: profile,
        id: params[:id]
      ).call

      head :no_content
    end

    private

    def load_profile
      Education::Profiles::Load.new(user: current_user).call
    end
  end
end
