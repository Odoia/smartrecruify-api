class CreateEmploymentRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :employment_records do |t|
      t.references :user, null: false, foreign_key: true

      t.string  :company_name, null: false
      t.string  :job_title,    null: false

      t.date    :started_on,   null: false
      t.date    :ended_on

      t.boolean :current,      null: false, default: false

      t.text    :job_description
      t.text    :responsibilities

      t.timestamps
    end

    add_index :employment_records, [:user_id, :started_on]
    add_index :employment_records, :company_name
    add_index :employment_records, :current
  end
end
