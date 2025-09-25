# frozen_string_literal: true

module Education
  module LanguageSkills
    # app/services/education/language_skills/list.rb
    class List
      def initialize(profile:)
        @profile = profile
      end

      def call
        @profile.language_skills.order(language: :asc)
      end

      private

      attr_reader :profile
    end
  end
end
