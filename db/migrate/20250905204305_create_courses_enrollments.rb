class CreateCoursesEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :course_enrollments do |t|
      t.references :education_profile, null: false, foreign_key: true
      t.references :course,            null: false, foreign_key: true

      # Enrollment status
      t.integer :status, null: false, default: 0
      # enum: { default: 0, enrolled: 1, in_progress: 2, completed: 3, dropped: 4 }

      t.date    :started_on
      t.date    :expected_end_on
      t.date    :completed_on
      t.integer :progress_percent

      t.timestamps
    end

    add_index :course_enrollments, [:education_profile_id, :course_id], unique: true, name: "idx_course_enrollments_unique"
    add_index :course_enrollments, :status
  end
end
