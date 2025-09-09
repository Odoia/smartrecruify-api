class CreateEducationProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :education_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      # Highest declared degree for quick filtering (redundant summary)
      t.integer :highest_degree, null: false, default: 0
      # enum: { default: 0, primary: 1, secondary: 2, high_school: 3,
      #         vocational: 4, associate: 5, bachelor: 6, postgraduate: 7,
      #         master: 8, doctorate: 9 }

      t.timestamps
    end
  end
end
