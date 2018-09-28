class CreateClientUsage < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenBillingDbConnection.config_key) do
      create_table :client_usages do |t|
        t.column :client_id, :integer, null: false
        t.column :registration_count, :integer, null: false
        t.column :kyc_submissions_count, :integer, null: false
        t.timestamps
      end

      add_index :client_usages, [:client_id], unique: true, name: 'uniq_client_id'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenBillingDbConnection.config_key) do
      drop_table :client_usages
    end
  end

end