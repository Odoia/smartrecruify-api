# frozen_string_literal: true

# app/models/education_profile.rb
class EducationProfile < ApplicationRecord
  belongs_to :user

  has_many :education_records, dependent: :destroy
  has_many :course_enrollments, dependent: :destroy
  has_many :courses, through: :course_enrollments
  has_many :language_skills, dependent: :destroy

  # Summary degree for quick filtering/search
  enum :highest_degree, {
    default: 0, primary: 1, secondary: 2, high_school: 3,
    vocational: 4, associate: 5, bachelor: 6, postgraduate: 7, master: 8, doctorate: 9
  }, default: :default

  validates :user_id, presence: true
end
