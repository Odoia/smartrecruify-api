class CreateEducationRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :education_records do |t|
      t.references :education_profile, null: false, foreign_key: true

      # Degree level for this specific record (may differ from profile.highest_degree)
      t.integer :degree_level, null: false, default: 0
      # enum (same scale as highest_degree)

      t.string  :institution_name, null: false
      t.string  :program_name,     null: false   # e.g., "Information Systems"

      t.date    :started_on
      t.date    :expected_end_on
      t.date    :completed_on

      # Study status
      t.integer :status, null: false, default: 0
      # enum: { default: 0, enrolled: 1, in_progress: 2, completed: 3, paused: 4, dropped: 5 }

      t.float   :gpa
      t.string  :transcript_url

      t.timestamps
    end

    add_index :education_records, [:education_profile_id, :degree_level]
    add_index :education_records, :status
  end
end
