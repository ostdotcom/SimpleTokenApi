class CreateClientKycDetailApiActivations < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      create_table :client_kyc_detail_api_activations do |t|
        t.column :client_id, :integer, null: false
        t.column :allowed_keys, :integer, null: false
        t.column :status, :tinyint, limit: 2, null: false
        t.timestamps
      end

      add_index :client_kyc_detail_api_activations, [:client_id, :status], unique: false, name: 'uniq_client_id_status'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_kyc_detail_api_activations
    end
  end

end