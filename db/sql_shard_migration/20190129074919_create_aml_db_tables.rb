module SqlShardMigration
  class CreateAmlDbTables < Base

    def up
      run_migration_for_db(db_config_key) do

        create_table :aml_searches do |t|
          t.column :uuid, :string, limit: 100, null: false
          t.column :user_kyc_detail_id, :integer, limit: 8, null: false
          t.column :user_extended_detail_id, :integer, limit: 8, null: false
          t.column :status, :tinyint, limit: 4, null: false
          t.column :steps_done, :tinyint, limit: 4, null: false, default: 0
          t.column :retry_count, :tinyint, limit: 4, null: false
          t.column :lock_id, :string, limit: 50, null: true
          t.timestamps
        end
        add_index :aml_searches, [:user_kyc_detail_id, :user_extended_detail_id], unique: true, name: 'uniq_user_kyc_detail_id_user_extended_detail_id'
        add_index :aml_searches, [:lock_id], unique: false, name: 'lock_id'


        create_table :aml_matches do |t|
          t.column :aml_search_uuid, :string, limit: 100, null: false
          t.column :match_id, :string, limit: 30, null: true
          t.column :qr_code, :string, limit: 30, null: false
          t.column :status, :tinyint, limit: 4, null: false
          t.column :data, :binary, limit: 1.megabyte, null: false
          t.column :pdf_path, :string, limit: 500, null: true
          t.timestamps
        end
        add_index :aml_matches, [:aml_search_uuid, :qr_code], unique: true, name: 'uniq_aml_search_uuid_qr_code'


        create_table :aml_logs do |t|
          t.column :aml_search_uuid, :string, limit: 100, null: false
          t.column :request_type, :tinyint, limit: 4, null: false
          t.column :response, :binary, :limit => 1.megabyte, null: true
          t.timestamps
        end
        add_index :aml_logs, [:aml_search_uuid], unique: false, name: 'aml_search_uuid'


      end
    end

    def down
      run_migration_for_db(db_config_key) do

        drop_table :aml_searches
        drop_table :aml_matches
        drop_table :aml_logs

      end
    end

    def database_shard_type
      'aml'
    end

  end
end
