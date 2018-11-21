class ModifyUpdatedByInKycDetailApiActivationColumn < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_kyc_detail_api_activations, :created_by
      rename_column :client_kyc_detail_api_activations, :updated_by, :last_acted_by
      rename_column :client_kyc_detail_api_activations, :allowed_keys, :kyc_fields
      add_column :client_kyc_detail_api_activations, :extra_kyc_fields, :string, limit: 500, after: :kyc_fields, null: true
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_kyc_detail_api_activations, :created_by, :integer, after: :status, :null => false
      rename_column :client_kyc_detail_api_activations, :last_acted_by, :updated_by
      rename_column :client_kyc_detail_api_activations, :kyc_fields, :allowed_keys
      remove_column :client_kyc_detail_api_activations, :extra_kyc_fields
    end
  end
end
