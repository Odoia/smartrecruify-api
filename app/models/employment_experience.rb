# frozen_string_literal: true

# app/models/employment_experience.rb
class EmploymentExperience < ApplicationRecord
  belongs_to :employment_record

  validates :title, presence: true
  validate  :ended_on_after_started_on

  private

  def ended_on_after_started_on
    return if ended_on.blank? || started_on.blank?
    errors.add(:ended_on, "must be on or after started_on") if ended_on < started_on
  end
end
