# frozen_string_literal: true

module Education
  module LanguageSkills
    # app/services/education/language_skills/update.rb
    class Update
      def initialize(profile:, id:, attrs:)
        @profile = profile
        @id      = id
        @attrs   = attrs || {}
      end

      def call
        skill = @profile.language_skills.find(@id)
        skill.update!(@attrs)
        skill
      end

      private

      attr_reader :profile, :id, :attrs
    end
  end
end
