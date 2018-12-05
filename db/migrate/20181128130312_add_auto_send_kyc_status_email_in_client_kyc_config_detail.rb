class AddAutoSendKycStatusEmailInClientKycConfigDetail < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_kyc_config_details, :auto_send_kyc_emails, :tinyint,  after: :extra_kyc_fields, null: false, default: 0
    end
    auto_kyc_status_bit_value = 0
    ClientKycConfigDetail.auto_send_kyc_emails_config.each do |_, value|
      auto_kyc_status_bit_value += value
    end
    ClientKycConfigDetail.update_all(auto_send_kyc_emails: auto_kyc_status_bit_value)
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_kyc_config_details, :auto_send_kyc_emails
    end
  end
end
