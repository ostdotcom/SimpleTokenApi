class CreateAmlLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishOstKycAmlDbConnection.config_key) do

      create_table :aml_logs do |t|
        t.column :aml_search_uuid, :integer, limit: 8, null: false
        t.column :request_type, :tinyint, limit: 4, null: false
        t.column :response, :text, null: true
        t.timestamps
      end
      add_index :aml_logs, [:aml_search_uuid], unique: false, name: 'aml_search_uuid'

    end
  end

  def down
    run_migration_for_db(EstablishOstKycAmlDbConnection.config_key) do
      drop_table :aml_logs
    end
  end
end
