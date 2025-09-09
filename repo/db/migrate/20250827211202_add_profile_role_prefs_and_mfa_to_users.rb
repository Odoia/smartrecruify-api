class AddProfileRolePrefsAndMfaToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :locale, :string,  default: "pt-BR"
    add_column :users, :timezone, :string, default: "America/Sao_Paulo"

    add_column :users, :terms_accepted_at,    :datetime
    add_column :users, :privacy_accepted_at,  :datetime
    add_column :users, :marketing_consent_at, :datetime

    add_column :users, :role, :integer, null: false, default: 0
    add_index  :users, :role

    add_column :users, :phone_number, :string
    add_index  :users, :phone_number

    add_column :users, :mfa_enabled,         :boolean, null: false, default: false
    add_column :users, :mfa_method,          :string
    add_column :users, :totp_secret,         :string
    add_column :users, :otp_digest,          :string
    add_column :users, :otp_expires_at,      :datetime

    add_column :users, :otp_backup_codes, :string, array: true, default: []
    add_column :users, :last_otp_sent_at,  :datetime
    add_column :users, :failed_otp_attempts, :integer, default: 0

    remove_index :users, :email if index_exists?(:users, :email)
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
  end
end
