# frozen_string_literal: true

module Education
  module LanguageSkills
    # app/services/education/language_skills/destroy.rb
    class Destroy
      def initialize(profile:, id:)
        @profile = profile
        @id      = id
      end

      def call
        skill = @profile.language_skills.find(@id)
        skill.destroy!
        true
      end

      private

      attr_reader :profile, :id
    end
  end
end
