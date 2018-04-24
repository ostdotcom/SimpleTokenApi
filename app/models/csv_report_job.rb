class CsvReportJob < EstablishSimpleTokenLogDbConnection

  serialize :extra_data, Hash

  enum status: {
      GlobalConstant::CsvReportJob.pending_status => 1,
      GlobalConstant::CsvReportJob.started_status => 2,
      GlobalConstant::CsvReportJob.completed_status => 3,
      GlobalConstant::CsvReportJob.failed_status => 4
  }


end