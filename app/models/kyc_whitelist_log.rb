class KycWhitelistLog < EstablishSimpleTokenContractInteractionsDbConnection

  enum status: {
      GlobalConstant::KycWhitelistLog.pending_status => 0,
      GlobalConstant::KycWhitelistLog.done_status => 1,
      GlobalConstant::KycWhitelistLog.confirmed_status => 2,
      GlobalConstant::KycWhitelistLog.failed_status => 3
  }, _suffix: true

  enum is_attention_needed: {
      GlobalConstant::KycWhitelistLog.attention_not_needed => 0,
      GlobalConstant::KycWhitelistLog.attention_needed => 1
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
    self.save!
  end

  # Mark failed
  #
  # * Author: Sachin, Aniket
  # * Date: 26/10/2017
  # * Reviewed By:
  #
  def mark_failed
    Rails.logger.info("user_kyc_whitelist_log - #{self.id} - Changing status to failed")
    self.status = GlobalConstant::KycWhitelistLog.failed_status
    self.save!
  end

  # Mark failed
  #
  # * Author: Sachin, Aniket
  # * Date: 26/10/2017
  # * Reviewed By:
  #
  def mark_is_attention_needed
    Rails.logger.info("user_kyc_whitelist_log - #{self.id} - Changing is_attention_needed to attention_needed")
    self.is_attention_needed = GlobalConstant::KycWhitelistLog.attention_needed
    self.save! if self.changed?
  end

end
