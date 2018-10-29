class AddCreatedByAndUpdatedByColumnInClientKycDetailApiActivation < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_kyc_detail_api_activations, :created_by, :integer, after: :status, :null => false
      add_column :client_kyc_detail_api_activations, :updated_by, :integer, after: :created_by, :null => false
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_kyc_detail_api_activations, :updated_by
      remove_column :client_kyc_detail_api_activations, :created_by
    end
  end
end
