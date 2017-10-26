class UserKycWhitelistLog < EstablishSimpleTokenLogDbConnection

  enum status: {
           GlobalConstant::UserKycWhitelistLog.pending_status => 0,
           GlobalConstant::UserKycWhitelistLog.done_status => 1,
           GlobalConstant::UserKycWhitelistLog.confirmed_status => 2
       }, _suffix: true

  enum is_attention_needed: {
      GlobalConstant::UserKycWhitelistLog.attention_not_needed => 0,
      GlobalConstant::UserKycWhitelistLog.attention_needed => 1
  }

  scope :kyc_whitelist_non_confirmed, -> {
    where(
      status: GlobalConstant::UserKycWhitelistLog.kyc_whitelist_confirmation_pending_statuses
    )
  }

end
