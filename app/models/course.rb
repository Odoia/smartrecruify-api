# app/models/course.rb
class Course < ApplicationRecord
  has_many :course_enrollments, dependent: :restrict_with_error

  enum :category, {
    default: 0, technology: 1, business: 2, language: 3, design: 4, data: 5, other: 6
  }, default: :default

  validates :name, presence: true
end
