# app/models/education_record.rb
class EducationRecord < ApplicationRecord
  belongs_to :education_profile

  enum :degree_level, {
    default: 0, primary: 1, secondary: 2, high_school: 3,
    vocational: 4, associate: 5, bachelor: 6, postgraduate: 7, master: 8, doctorate: 9
  }, default: :default, prefix: :degree_level

  enum :status, {
    default: 0, enrolled: 1, in_progress: 2, completed: 3, paused: 4, dropped: 5
  }, default: :default, prefix: :status

  validates :institution_name, :program_name, presence: true
  validate :dates_consistency

  private

  # Keep dates coherent with the status and common sense.
  def dates_consistency
    if completed_on.present?
      errors.add(:status, "must be completed when completed_on is present") unless status == "completed"
      errors.add(:completed_on, "must be after started_on") if started_on && completed_on < started_on
    end
  end
end
