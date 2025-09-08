class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      # Catalog of courses (short/medium training, certificates, languages, etc.)
      t.string  :name,       null: false
      t.string  :provider                      # e.g., "Coursera", "Udemy"
      t.integer :category,   null: false, default: 0
      # enum: { default: 0, technology: 1, business: 2, language: 3, design: 4, data: 5, other: 6 }

      t.integer :hours
      t.text    :description

      t.timestamps
    end

    add_index :courses, [:name, :provider]
    add_index :courses, :category
  end
end
