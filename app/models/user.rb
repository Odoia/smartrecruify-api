class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable,
    :jwt_authenticatable, jwt_revocation_strategy: JwtRedisDenylist

  enum :role, { default: 0, normal: 1, premium: 2 }, default: :default, prefix: :role

  has_one  :education_profile, dependent: :destroy

  # education
  has_many :education_records,    through: :education_profile
  has_many :course_enrollments,   through: :education_profile
  has_many :language_skills,      through: :education_profile
  has_many :courses,              through: :course_enrollments

  # employment
  has_many :employment_records, dependent: :destroy

  # ensure profile exists (útil nos controllers)
  def ensure_education_profile!
    education_profile || create_education_profile!
  end
end
