class KycWhitelistLog < EstablishSimpleTokenContractInteractionsDbConnection

  enum status: {
      GlobalConstant::KycWhitelistLog.pending_status => 0,
      GlobalConstant::KycWhitelistLog.done_status => 1,
      GlobalConstant::KycWhitelistLog.confirmed_status => 2,
      GlobalConstant::KycWhitelistLog.failed_status => 3
  }, _suffix: true

  enum failed_reason: {
      GlobalConstant::KycWhitelistLog.not_failed => 0,
      GlobalConstant::KycWhitelistLog.invalid_kyc_failed => 1,
      GlobalConstant::KycWhitelistLog.invalid_transaction_failed => 2,
      GlobalConstant::KycWhitelistLog.invalid_event_failed => 3
  }

  scope :kyc_whitelist_non_confirmed, -> {
    where(
        status: GlobalConstant::KycWhitelistLog.kyc_whitelist_confirmation_pending_statuses
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
    self.status = GlobalConstant::KycWhitelistLog.confirmed_status
    self.save! if self.changed?
  end

  # Mark failed
  #
  # * Author: Sachin, Aniket
  # * Date: 26/10/2017
  # * Reviewed By:
  #
  def mark_failed_with_reason(failed_reason)
    Rails.logger.info("user_kyc_whitelist_log - #{self.id} - mark as failed.")
    self.status = GlobalConstant::KycWhitelistLog.failed_status
    self.failed_reason = failed_reason
    self.save! if self.changed?
  end

end
