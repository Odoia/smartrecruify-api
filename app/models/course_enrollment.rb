# app/models/course_enrollment.rb
class CourseEnrollment < ApplicationRecord
  belongs_to :education_profile
  belongs_to :course

  enum :status, {
    default: 0, enrolled: 1, in_progress: 2, completed: 3, dropped: 4
  }, default: :default

  validates :progress_percent, inclusion: { in: 0..100 }, allow_nil: true
  validate :completion_requires_completed_status

  private

  def completion_requires_completed_status
    if completed_on.present? && status != "completed"
      errors.add(:status, "must be completed when completed_on is present")
    end
  end
end
