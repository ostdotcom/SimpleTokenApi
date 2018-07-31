class RenameClientKycAutoApproveSettingsIdInUserKycComparisionDetail < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_comparison_details, :client_kyc_auto_approve_settings_id, :client_kyc_pass_settings_id
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_comparison_details, :client_kyc_pass_settings_id, :client_kyc_auto_approve_settings_id
    end
  end

end
