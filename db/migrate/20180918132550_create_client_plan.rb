class CreateClientPlan < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenBillingDbConnection.config_key) do
      create_table :client_plan do |t|
        t.column :client_id, :integer, null: false
        t.column :add_ons, :tinyint, limit: 1, null: false, default: 0
        t.column :kyc_submissions_count, :integer, null: false
        t.column :notification_type, :tinyint, limit: 1, null: false, default: 0
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end

      add_index :client_plan, [:client_id], unique: true, name: 'uniq_client_id'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenBillingDbConnection.config_key) do
      drop_table :client_plan
    end
  end

end