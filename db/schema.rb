# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_09_193627) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "course_enrollments", force: :cascade do |t|
    t.bigint "education_profile_id", null: false
    t.bigint "course_id", null: false
    t.integer "status", default: 0, null: false
    t.date "started_on"
    t.date "expected_end_on"
    t.date "completed_on"
    t.integer "progress_percent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_enrollments_on_course_id"
    t.index ["education_profile_id", "course_id"], name: "idx_course_enrollments_unique", unique: true
    t.index ["education_profile_id"], name: "index_course_enrollments_on_education_profile_id"
    t.index ["status"], name: "index_course_enrollments_on_status"
  end

  create_table "courses", force: :cascade do |t|
    t.string "name", null: false
    t.string "provider"
    t.integer "category", default: 0, null: false
    t.integer "hours"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_courses_on_category"
    t.index ["name", "provider"], name: "index_courses_on_name_and_provider"
  end

  create_table "education_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "highest_degree", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_education_profiles_on_user_id", unique: true
  end

  create_table "education_records", force: :cascade do |t|
    t.bigint "education_profile_id", null: false
    t.integer "degree_level", default: 0, null: false
    t.string "institution_name", null: false
    t.string "program_name", null: false
    t.date "started_on"
    t.date "expected_end_on"
    t.date "completed_on"
    t.integer "status", default: 0, null: false
    t.float "gpa"
    t.string "transcript_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["education_profile_id", "degree_level"], name: "idx_on_education_profile_id_degree_level_be8bb736b1"
    t.index ["education_profile_id"], name: "index_education_records_on_education_profile_id"
    t.index ["status"], name: "index_education_records_on_status"
  end

  create_table "employment_experiences", force: :cascade do |t|
    t.bigint "employment_record_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "impact"
    t.string "skills", default: [], array: true
    t.string "tools", default: [], array: true
    t.string "tags", default: [], array: true
    t.jsonb "metrics", default: {}
    t.date "started_on"
    t.date "ended_on"
    t.integer "order_index", default: 0
    t.string "reference_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employment_record_id", "order_index"], name: "idx_on_employment_record_id_order_index_0563b63926"
    t.index ["employment_record_id"], name: "index_employment_experiences_on_employment_record_id"
    t.index ["metrics"], name: "index_employment_experiences_on_metrics", using: :gin
    t.index ["skills"], name: "index_employment_experiences_on_skills", using: :gin
    t.index ["tags"], name: "index_employment_experiences_on_tags", using: :gin
    t.index ["tools"], name: "index_employment_experiences_on_tools", using: :gin
  end

  create_table "employment_records", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "company_name", null: false
    t.string "job_title", null: false
    t.date "started_on", null: false
    t.date "ended_on"
    t.boolean "current", default: false, null: false
    t.text "job_description"
    t.text "responsibilities"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_name"], name: "index_employment_records_on_company_name"
    t.index ["current"], name: "index_employment_records_on_current"
    t.index ["user_id", "started_on"], name: "index_employment_records_on_user_id_and_started_on"
    t.index ["user_id"], name: "index_employment_records_on_user_id"
  end

  create_table "language_skills", force: :cascade do |t|
    t.bigint "education_profile_id", null: false
    t.integer "language", default: 0, null: false
    t.integer "level", default: 0, null: false
    t.string "certificate_name"
    t.string "certificate_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["education_profile_id", "language"], name: "idx_language_unique_per_profile", unique: true
    t.index ["education_profile_id"], name: "index_language_skills_on_education_profile_id"
    t.index ["level"], name: "index_language_skills_on_level"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "locale", default: "pt-BR"
    t.string "timezone", default: "America/Sao_Paulo"
    t.datetime "terms_accepted_at"
    t.datetime "privacy_accepted_at"
    t.datetime "marketing_consent_at"
    t.integer "role", default: 0, null: false
    t.string "phone_number"
    t.boolean "mfa_enabled", default: false, null: false
    t.string "mfa_method"
    t.string "totp_secret"
    t.string "otp_digest"
    t.datetime "otp_expires_at"
    t.string "otp_backup_codes", default: [], array: true
    t.datetime "last_otp_sent_at"
    t.integer "failed_otp_attempts", default: 0
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "course_enrollments", "courses"
  add_foreign_key "course_enrollments", "education_profiles"
  add_foreign_key "education_profiles", "users"
  add_foreign_key "education_records", "education_profiles"
  add_foreign_key "employment_experiences", "employment_records"
  add_foreign_key "employment_records", "users"
  add_foreign_key "language_skills", "education_profiles"
end
