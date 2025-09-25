# frozen_string_literal: true

module Education
  # app/controllers/education/language_skills_controller.rb
  class LanguageSkillsController < ApplicationController
    before_action :authenticate_user!

    def index
      profile = load_profile

      skills = Education::LanguageSkills::List.new(
        profile: profile,
        filters: filter_params.to_h.symbolize_keys
      ).call

      render json: skills, status: :ok
    end

    def create
      profile = load_profile

      skill = Education::LanguageSkills::Upsert.new(
        profile:  profile,
        language: language_skill_params[:language],
        level:    language_skill_params[:level],
        attrs:    language_skill_params.except(:language, :level)
      ).call

      render json: skill, status: :created
    end

    def update
      profile = load_profile

      skill = Education::LanguageSkills::Update.new(
        profile: profile,
        id:      params[:id],
        attrs:   language_skill_params
      ).call

      render json: skill, status: :ok
    end

    def destroy
      profile = load_profile

      Education::LanguageSkills::Destroy.new(
        profile: profile,
        id:      params[:id]
      ).call

      head :no_content
    end

    private

    def load_profile
      Education::Profiles::Load.new(user: current_user).call
    end

    def language_skill_params
      params
        .require(:language_skill)
        .permit(:language, :level, :certificate_name, :certificate_score)
    end

    def filter_params
      params
        .fetch(:filter, {})
        .permit(:language, :level)
    end
  end
end
