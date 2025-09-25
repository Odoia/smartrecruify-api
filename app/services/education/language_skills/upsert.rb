# frozen_string_literal: true

module Education
  module LanguageSkills
    # app/services/education/language_skills/upsert.rb
    class Upsert
      # attrs: { certificate_name:, certificate_score: } (opcionais)
      def initialize(profile:, language:, level:, attrs: {})
        @profile  = profile
        @language = language
        @level    = level
        @attrs    = attrs || {}
      end

      def call
        skill = @profile.language_skills.find_or_initialize_by(language: @language)
        skill.assign_attributes({ level: @level }.merge(@attrs))
        skill.save!
        skill
      end

      private

      attr_reader :profile, :language, :level, :attrs
    end
  end
end
