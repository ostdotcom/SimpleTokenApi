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

  # Mark confirmed
  #
  # * Author: Kedar, Abhay
  # * Date: 26/10/2017
  # * Reviewed By: Sunil
  #
  def mark_confirmed
    Rails.logger.info("user_kyc_whitelist_log - #{self.id} - Changing status to confirmed")
    self.status = GlobalConstant::UserKycWhitelistLog.confirmed_status
    self.save!
    # change flag to attention required
  end

end
