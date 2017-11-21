class CreateEditKycRequests < DbMigrationConnection

  def self.up

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do

      create_table :edit_kyc_requests do |t|
        t.column :case_id, :integer, null: false
        t.column :admin_id, :integer, null: false
        t.column :user_id, :integer, null: false
        t.column :ethereum_address, :blob #encrypted
        t.column :open_case_only, :integer, limit: 1
        t.column :debug_data, :text
        t.column :status, :integer, limit: 1, :default => 0
        t.timestamps
      end

    end

  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :edit_kyc_requests
    end
  end

end
