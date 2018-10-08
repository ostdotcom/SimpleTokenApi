class ModifyCynopsisStatusToAmlStatus < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_details, :cynopsis_status, :aml_status
      rename_column :user_kyc_details, :cynopsis_user_id, :aml_user_id
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      rename_column :user_kyc_details, :aml_status, :cynopsis_status
      rename_column :user_kyc_details, :aml_user_id, :cynopsis_user_id
    end
  end
end

