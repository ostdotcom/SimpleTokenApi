class MfaLog < EstablishSimpleTokenAdminDbConnection
  enum status: {
      GlobalConstant::MfaLog.active_status => 1,
      GlobalConstant::MfaLog.deleted_status => 2
  }
end
