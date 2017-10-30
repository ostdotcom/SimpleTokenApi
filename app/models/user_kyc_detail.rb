class UserKycDetail < EstablishSimpleTokenUserDbConnection

  enum cynopsis_status: {
           GlobalConstant::UserKycDetail.un_processed_cynopsis_status => 1, # yello
           GlobalConstant::UserKycDetail.pending_cynopsis_status => 2, # yello
           GlobalConstant::UserKycDetail.cleared_cynopsis_status => 3, # green
           GlobalConstant::UserKycDetail.approved_cynopsis_status => 4, # green
           GlobalConstant::UserKycDetail.rejected_cynopsis_status => 5 # red
       }

  enum admin_status: {
           GlobalConstant::UserKycDetail.un_processed_admin_status => 1, # yello
           GlobalConstant::UserKycDetail.qualified_admin_status => 2, # green
           GlobalConstant::UserKycDetail.denied_admin_status => 3 # red
       }

  enum token_sale_participation_phase: {
      GlobalConstant::TokenSale.early_access_token_sale_phase => 1,
      GlobalConstant::TokenSale.general_access_token_sale_phase => 2
  }

  enum kyc_duplicate_status: {
         GlobalConstant::UserKycDetail.unprocessed_kyc_duplicate_status => 0,
         GlobalConstant::UserKycDetail.never_kyc_duplicate_status => 1,
         GlobalConstant::UserKycDetail.is_kyc_duplicate_status => 2,
         GlobalConstant::UserKycDetail.was_kyc_duplicate_status => 3
     }, _suffix: true

  enum email_duplicate_status: {
          GlobalConstant::UserKycDetail.no_email_duplicate_status => 0,
          GlobalConstant::UserKycDetail.yes_email_duplicate_status => 1
      }, _suffix: true

  enum whitelist_status: {
      GlobalConstant::UserKycDetail.unprocessed_whitelist_status => 0,
      GlobalConstant::UserKycDetail.started_whitelist_status => 1,
      GlobalConstant::UserKycDetail.done_whitelist_status => 2,
      GlobalConstant::UserKycDetail.failed_whitelist_status => 3
  }, _suffix: true

  enum admin_action_type: {
      GlobalConstant::UserKycDetail.no_admin_action_type => 0,
      GlobalConstant::UserKycDetail.data_mismatch_admin_action_type => 1,
      GlobalConstant::UserKycDetail.passport_issue_admin_action_type => 2,
      GlobalConstant::UserKycDetail.selfie_issue_admin_action_type => 3,
      GlobalConstant::UserKycDetail.residency_issue_admin_action_type => 4
  }, _suffix: true

  scope :kyc_admin_and_cynopsis_approved, -> { where(cynopsis_status: GlobalConstant::UserKycDetail.cynopsis_approved_statuses, admin_status: GlobalConstant::UserKycDetail.admin_approved_statuses) }
  scope :whitelist_status_unprocessed, -> { where(whitelist_status: GlobalConstant::UserKycDetail.unprocessed_whitelist_status) }

  after_commit :memcache_flush

  def kyc_approved?
    GlobalConstant::UserKycDetail.cynopsis_approved_statuses.include?(cynopsis_status) && GlobalConstant::UserKycDetail.admin_approved_statuses.include?(admin_status)
  end

  def kyc_denied?
    (cynopsis_status == GlobalConstant::UserKycDetail.rejected_cynopsis_status) || (admin_status == GlobalConstant::UserKycDetail.denied_admin_status)
  end

  def case_closed?
    kyc_approved? || kyc_denied?
  end

  def kyc_pending?
    !kyc_approved? && !kyc_denied?
  end

  def show_duplicate_status

    [
        GlobalConstant::UserKycDetail.unprocessed_kyc_duplicate_status,
        GlobalConstant::UserKycDetail.is_kyc_duplicate_status
    ].include?(kyc_duplicate_status) || email_duplicate_status == GlobalConstant::UserKycDetail.yes_email_duplicate_status

  end

  def never_duplicate?

    [
        GlobalConstant::UserKycDetail.unprocessed_kyc_duplicate_status,
        GlobalConstant::UserKycDetail.never_kyc_duplicate_status
    ].include?(self.kyc_duplicate_status) && email_duplicate_status != GlobalConstant::UserKycDetail.yes_email_duplicate_status

  end

  def self.get_cynopsis_user_id(user_id)
    "ts_#{Rails.env[0]}_#{user_id}"
  end

  # Get Key Object
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Kedar
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_memcache_key_object
    MemcacheKey.new('user.user_kyc_details')
  end

  # Get/Set Memcache data for UserKycDetail
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Kedar
  #
  # @param [Integer] user_id - user id
  #
  # @return [AR] UserKycDetail object
  #
  def self.get_from_memcache(user_id)
    memcache_key_object = UserKycDetail.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {user_id: user_id}, memcache_key_object.expiry) do
      UserKycDetail.where(user_id: user_id).first
    end
  end

  # Bulk Flush Memcache
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Kedar
  #
  def self.bulk_flush(user_ids)
    user_ids.each do |uid|
      user_details_memcache_key = UserKycDetail.get_memcache_key_object.key_template % {user_id: uid}
      Memcache.delete(user_details_memcache_key)
    end
  end

  private

  # Flush Memcache
  #
  # * Author: Abhay
  # * Date: 30/10/2017
  # * Reviewed By: Kedar
  #
  def memcache_flush
    bulk_flush([self.user_id])
  end

end
