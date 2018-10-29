class CreateVerifiedOperatorAddresses < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      create_table :verified_operator_addresses do |t|
        t.column :address, :string, limit: 100, null: false
        t.column :client_id, :integer, limit: 8, null: true
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end

      add_index :verified_operator_addresses, [:status, :client_id], unique: false, name: 'status_client_id'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :verified_operator_addresses
    end
  end

end

