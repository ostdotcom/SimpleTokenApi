class AddColumnReportTypeInCsvReportJob < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      add_column :csv_report_jobs, :report_type, :tinyint, limit: 4, null: true, after: :client_id
    end
    CsvReportJob.update_all(report_type: GlobalConstant::CsvReportJob.kyc_report_type)

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      change_column :csv_report_jobs, :report_type, :tinyint, limit: 4, null: false
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      remove_column :csv_report_jobs, :report_type
    end
  end
end
