class CreateImageProcessingLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :image_processing_logs do |t|
        t.column :user_kyc_comparison_detail_id, :bigint, null: false
        t.column :service_used, :tinyint, limit: 2, null: false
        t.column :input_params, :text, null: false
        t.column :debug_data, :blob #Encrypted
        t.timestamps
      end

      add_index :image_processing_logs, :user_kyc_comparison_detail_id, name: 'user_kyc_comparison_detail_indx'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :image_processing_logs
    end
  end
end
