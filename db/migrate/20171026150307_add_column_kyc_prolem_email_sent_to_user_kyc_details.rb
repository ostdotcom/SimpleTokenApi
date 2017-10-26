class AddColumnKycProlemEmailSentToUserKycDetails < DbMigrationConnection

  def self.up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_kyc_details, :kyc_prolem_email_sent, :tinyint, limit: 1, null: false, after: :whitelist_status
    end
  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :kyc_prolem_email_sent
    end
  end

end
