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

ActiveRecord::Schema[8.0].define(version: 2025_08_27_211202) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
end
