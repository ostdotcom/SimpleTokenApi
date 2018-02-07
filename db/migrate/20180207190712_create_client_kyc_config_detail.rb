class CreateClientKycConfigDetail < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      create_table :client_kyc_config_details do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :kyc_fields, :integer, null: false
        t.column :residency_proof_nationalities, :text, null: true
        t.timestamps
      end

      add_index :client_kyc_config_details, [:client_id], unique: true, name: 'uniq_client_id'
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_kyc_config_details
    end
  end

end
