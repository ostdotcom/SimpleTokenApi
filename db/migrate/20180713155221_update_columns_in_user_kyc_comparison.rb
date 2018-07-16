class UpdateColumnsInUserKycComparison < DbMigrationConnection
  def change
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_kyc_comparison_details, :lock_id, :string, null: true
    end
  end
end
