class CreateClientKycAutoApproveSettings < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      create_table :client_kyc_auto_approve_settings do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :face_match_percent, :decimal, precision:5, scale:2, null: false, default: 0
        t.column :ocr_comparison_fields, :integer, null: false, default: 0
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end
      add_index :client_kyc_auto_approve_settings, [:client_id, :status], name: 'client_id_status_indx'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_kyc_auto_approve_settings
    end
  end
end
