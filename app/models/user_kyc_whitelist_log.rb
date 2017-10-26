class UserKycWhitelistLog < EstablishSimpleTokenLogDbConnection

  enum status: {
           GlobalConstant::UserKycWhitelistLog.pending_status => 0,
           GlobalConstant::UserKycWhitelistLog.done_status => 1,
           GlobalConstant::UserKycWhitelistLog.confirmed_status => 2
       }, _suffix: true

  enum is_attention_needed: {
      GlobalConstant::UserKycDuplicationLog.attention_not_needed => 0,
      GlobalConstant::UserKycDuplicationLog.attention_needed => 1
  }
  
end
