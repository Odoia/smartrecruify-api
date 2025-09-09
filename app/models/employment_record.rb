# frozen_string_literal: true

# app/models/employment_record.rb
class EmploymentRecord < ApplicationRecord
  belongs_to :user
  has_many :employment_experiences, dependent: :destroy

  validates :company_name, :job_title, :started_on, presence: true
  validates :current, inclusion: { in: [true, false] }

  validate :ended_on_after_started_on
  validate :ended_on_blank_when_current

  private

  def ended_on_after_started_on
    return if ended_on.blank? || started_on.blank?
    errors.add(:ended_on, "must be on or after started_on") if ended_on < started_on
  end

  def ended_on_blank_when_current
    return unless current
    errors.add(:ended_on, "must be blank when current is true") if ended_on.present?
  end
end
