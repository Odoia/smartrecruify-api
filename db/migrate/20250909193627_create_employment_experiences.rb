class CreateEmploymentExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :employment_experiences do |t|
      t.references :employment_record, null: false, foreign_key: true

      t.string  :title,       null: false        # e.g., "Increased regional sales by 30%"
      t.text    :description                     # what/why/how
      t.string  :impact                           # concise outcome, e.g., "+30% sales", "-45% wait time"

      t.string  :skills, array: true, default: [] # universal: ["Negotiation","Pediatrics","SQL"]
      t.string  :tools,  array: true, default: [] # universal: ["Excel","Salesforce","EHR","LMS"]
      t.string  :tags,   array: true, default: [] # free classification: ["Leadership","Compliance"]

      t.jsonb   :metrics, default: {}             # free key-value numbers: {"pass_rate_pct":95}

      t.date    :started_on
      t.date    :ended_on

      t.integer :order_index, default: 0          # display order (0 = top)
      t.string  :reference_url                    # link to portfolio/press/etc.

      t.timestamps
    end

    add_index :employment_experiences, [:employment_record_id, :order_index]
    add_index :employment_experiences, :skills, using: :gin
    add_index :employment_experiences, :tools,  using: :gin
    add_index :employment_experiences, :tags,   using: :gin
    add_index :employment_experiences, :metrics, using: :gin
  end
end
