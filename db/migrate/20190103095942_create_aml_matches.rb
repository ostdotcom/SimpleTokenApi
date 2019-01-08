class CreateAmlMatches < DbMigrationConnection
  def up
    run_migration_for_db(EstablishOstKycAmlDbConnection.config_key) do

      create_table :aml_matches do |t|
        t.column :aml_search_uuid, :string, limit: 100, null: false
        t.column :match_id, :integer, limit: 30, null: true
        t.column :qr_code, :string, limit: 30, null: false
        t.column :data, :blob, null: false
        t.column :pdf_path, :string, limit: 500, null: true
        t.timestamps
      end
      add_index :aml_matches, [:aml_search_uuid, :qr_code], unique: true, name: 'uniq_aml_search_uuid_qr_code'
    end
  end

  def down
    run_migration_for_db(EstablishOstKycAmlDbConnection.config_key) do
      drop_table :aml_matches
    end
  end
end
