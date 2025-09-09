# app/models/language_skill.rb
class LanguageSkill < ApplicationRecord
  belongs_to :education_profile

  # Language catalog extensible as you requested
  enum :language, {
    default: 0, english: 1, spanish: 2, portuguese_brazil: 3, portuguese_portugal: 4, french: 5
  }, default: :default

  # Unified proficiency scale (works for any language)
  enum :level, {
    default: 0, beginner: 1, elementary: 2, intermediate: 3,
    upper_intermediate: 4, advanced: 5, proficient: 6
  }, default: :default

  validates :language, :level, presence: true
end
