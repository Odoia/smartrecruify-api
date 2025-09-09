# app/services/education/language_skills/upsert.rb
module Education
  module LanguageSkills
    class Upsert
      # Creates or updates a language skill (unique per language per profile)
      def self.call(profile:, language:, level:, attrs: {})
        skill = profile.language_skills.find_or_initialize_by(language: language)
        skill.assign_attributes({ level: level }.merge(attrs))
        skill.save!
        skill
      end
    end
  end
end
