class CreateCsvReportJob < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :csv_report_jobs do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :admin_id, :integer, limit: 8, null: false
        t.column :extra_data, :text, null: true
        t.column :status, :tinyint, null: false
        t.timestamps
      end

      add_index :csv_report_jobs, [:client_id, :status, :created_at], unique: false, name: 'client_id_status_created_at'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :csv_report_jobs
    end
  end

end
