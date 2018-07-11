class RenameAutoApproveFailedReasonInUserKycComparisionDetail < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_comparison_details, :auto_approve_failed_reason, :auto_approve_failed_reasons
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_comparison_details, :auto_approve_failed_reasons, :auto_approve_failed_reason
    end
  end

end
