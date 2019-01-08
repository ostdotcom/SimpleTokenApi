class CreateAmlSearches < DbMigrationConnection
  def up
    run_migration_for_db(EstablishOstKycAmlDbConnection.config_key) do

      create_table :aml_searches do |t|
        t.column :uuid, :string, limit: 100, null: false
        t.column :user_kyc_detail_id, :integer, limit: 8, null: false
        t.column :user_extended_detail_id, :integer, limit: 8, null: false
        t.column :status, :tinyint, limit: 4, null: false
        t.column :steps_done, :tinyint, limit: 4, null: false
        t.column :retry_count, :tinyint, limit: 4, null: false
        t.column :lock_id, :string, limit: 50, null: true
        t.timestamps
      end
      add_index :aml_searches, [:user_kyc_detail_id, :user_extended_detail_id], unique: true, name: 'uniq_user_kyc_detail_id_user_extended_detail_id'
      add_index :aml_searches, [:lock_id], unique: false, name: 'lock_id'

    end
  end

  def down
    run_migration_for_db(EstablishOstKycAmlDbConnection.config_key) do
      drop_table :aml_searches
    end
  end
end
