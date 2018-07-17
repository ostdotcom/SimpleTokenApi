class ModifyAutoApproveFailedReasonsColumn < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_kyc_comparison_details, :kyc_auto_approved_status, :integer , null: false, default: 0
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_kyc_comparison_details, :kyc_auto_approved_status, :integer, null: true
    end
  end
end
