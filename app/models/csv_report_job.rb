class CsvReportJob < EstablishSimpleTokenLogDbConnection

  serialize :extra_data, Hash

  enum status: {
      GlobalConstant::CsvReportJob.pending_status => 1,
      GlobalConstant::CsvReportJob.started_status => 2,
      GlobalConstant::CsvReportJob.completed_status => 3,
      GlobalConstant::CsvReportJob.failed_status => 4
  }

  enum report_type: {
      GlobalConstant::CsvReportJob.kyc_report_type => 1,
      GlobalConstant::CsvReportJob.user_report_type => 2
  }

end