class CreateLanguageSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :language_skills do |t|
      t.references :education_profile, null: false, foreign_key: true

      # Language catalog (extensible)
      t.integer :language, null: false, default: 0
      # enum: { default: 0, english: 1, spanish: 2, portuguese_brazil: 3, portuguese_portugal: 4, french: 5 }

      # Unified proficiency scale you requested
      t.integer :level, null: false, default: 0
      # enum: { default: 0, beginner: 1, elementary: 2, intermediate: 3, upper_intermediate: 4, advanced: 5, proficient: 6 }

      t.string  :certificate_name
      t.string  :certificate_score

      t.timestamps
    end

    add_index :language_skills, [:education_profile_id, :language], unique: true, name: "idx_language_unique_per_profile"
    add_index :language_skills, :level
  end
end
