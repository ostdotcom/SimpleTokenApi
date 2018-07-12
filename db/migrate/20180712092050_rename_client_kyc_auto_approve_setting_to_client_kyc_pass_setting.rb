class RenameClientKycAutoApproveSettingToClientKycPassSetting < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      rename_table :client_kyc_auto_approve_settings, :client_kyc_pass_settings
      add_column :client_kyc_pass_settings, :approve_type, :tinyint, after: :ocr_comparison_fields, default: 0
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_kyc_pass_settings, :approve_type
      rename_table :client_kyc_pass_settings, :client_kyc_auto_approve_settings
    end
  end
end
