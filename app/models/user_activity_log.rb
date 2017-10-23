class UserActivityLog < EstablishSimpleTokenLogDbConnection
  serialize :data, Hash

  enum log_type: {
           GlobalConstant::UserActivityLog.admin_log_type => 1,
           GlobalConstant::UserActivityLog.developer_log_type => 2
       }, _suffix: true

  enum action: {
           GlobalConstant::UserActivityLog.register_action => 1,
           GlobalConstant::UserActivityLog.double_opt_in_action => 2,
           GlobalConstant::UserActivityLog.update_kyc_action => 3,
           GlobalConstant::UserActivityLog.kyc_denied_action => 4,
           GlobalConstant::UserActivityLog.kyc_qualified_action => 5,
           GlobalConstant::UserActivityLog.data_mismatch_email_sent_action => 6,
           GlobalConstant::UserActivityLog.passport_issue_email_sent_action => 7,
           GlobalConstant::UserActivityLog.selfie_issue_email_sent_action => 8,
           GlobalConstant::UserActivityLog.residency_issue_email_sent_action => 9,
           GlobalConstant::UserActivityLog.login_action => 10
       }, _suffix: true


end
