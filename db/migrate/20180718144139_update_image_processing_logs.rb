class UpdateImageProcessingLogs < DbMigrationConnection
  def change
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      change_column :image_processing_logs, :debug_data, :mediumblob, null: true
    end
  end
end
