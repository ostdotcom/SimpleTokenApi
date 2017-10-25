class UserKycWhitelistLog < EstablishSimpleTokenLogDbConnection

  enum status: {
           GlobalConstant::UserKycWhitelistLog.pending_status => 0,
           GlobalConstant::UserKycWhitelistLog.update_event_obtained_status => 1,
           GlobalConstant::UserKycWhitelistLog.attention_needed_status => 2,
           GlobalConstant::UserKycWhitelistLog.confirmed_status => 3,
           GlobalConstant::UserKycWhitelistLog.failed_status => 4
       }

end
