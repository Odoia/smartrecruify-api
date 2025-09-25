# frozen_string_literal: true

# app/models/language_skill.rb
class LanguageSkill < ApplicationRecord
  belongs_to :education_profile

  enum :language, {
    default: 0, english: 1, spanish: 2, portuguese_brazil: 3, portuguese_portugal: 4, french: 5
  }, default: :default, prefix: true

  enum :level, {
    default: 0, beginner: 1, elementary: 2, intermediate: 3,
    upper_intermediate: 4, advanced: 5, proficient: 6
  }, default: :default, prefix: true

  validates :language, :level, presence: true
end
