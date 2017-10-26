class UserKycWhitelistLog < EstablishSimpleTokenLogDbConnection

  enum status: {
           GlobalConstant::UserKycWhitelistLog.pending_status => 0,
           GlobalConstant::UserKycWhitelistLog.done_status => 1,
           GlobalConstant::UserKycWhitelistLog.confirmed_status => 2
       }, _suffix: true

  enum attention_needed: {
           GlobalConstant::UserKycWhitelistLog.false_attention_needed=> 0,
           GlobalConstant::UserKycWhitelistLog.true_attention_needed => 1
       }, _prefix: true
end
