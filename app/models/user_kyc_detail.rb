class UserKycDetail < EstablishSimpleTokenUserDbConnection

  enum cynopsis_status: {
      GlobalConstant::UserKycDetail.unprocessed_cynopsis_status => 1, # yello
      GlobalConstant::UserKycDetail.pending_cynopsis_status => 2, # yello
      GlobalConstant::UserKycDetail.cleared_cynopsis_status => 3, # green
      GlobalConstant::UserKycDetail.approved_cynopsis_status => 4, # green
      GlobalConstant::UserKycDetail.rejected_cynopsis_status => 5, # red
      GlobalConstant::UserKycDetail.failed_cynopsis_status => 6 # red
  }, _suffix: true

  enum admin_status: {
      GlobalConstant::UserKycDetail.unprocessed_admin_status => 1, # yello
      GlobalConstant::UserKycDetail.qualified_admin_status => 2, # green
      GlobalConstant::UserKycDetail.denied_admin_status => 3 # red
  }, _suffix: true

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

  scope :kyc_admin_and_cynopsis_approved, -> {where(cynopsis_status: GlobalConstant::UserKycDetail.cynopsis_approved_statuses, admin_status: GlobalConstant::UserKycDetail.admin_approved_statuses)}
  scope :whitelist_status_unprocessed, -> {where(whitelist_status: GlobalConstant::UserKycDetail.unprocessed_whitelist_status)}

  scope :filter_by, -> (filters) {
    where_clause = {}
    where_bitwise_clause = {}
    filters.each do |key, val|
      filter_data = GlobalConstant::UserKycDetail.filters[key.to_s][val.to_s]
      if key.to_s === 'admin_action_types'
        where_bitwise_clause = filter_data
      else
        where_clause[key] = filter_data if filter_data.present?
      end
    end
    where(where_clause).where(where_bitwise_clause)
  }

  scope :sorting_by, -> (sortings) {
    order_clause = {}
    sortings.each do |key, val|
      sort_data = GlobalConstant::UserKycDetail.sorting[key.to_s][val.to_s]
      order_clause.merge!(sort_data) if sort_data.present?
    end
    order(order_clause)
  }

  after_commit :memcache_flush

  #todo: WEBCODECHANGE
  # enum admin_action_type: {
  #     GlobalConstant::UserKycDetail.no_admin_action_type => 0,
  #     GlobalConstant::UserKycDetail.data_mismatch_admin_action_type => 1,
  #     GlobalConstant::UserKycDetail.document_id_issue_admin_action_type => 2,
  #     GlobalConstant::UserKycDetail.selfie_issue_admin_action_type => 3,
  #     GlobalConstant::UserKycDetail.residency_issue_admin_action_type => 4
  # }, _suffix: true

  # Array of Properties symbols
  #
  # * Author: Aman
  # * Date: 25/04/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of properties bits set for user
  #
  def admin_action_types_array
    @admin_action_types_array = UserKycDetail.get_bits_set_for_admin_action_types(admin_action_type)
  end

  # properties config
  #
  # * Author: Aman
  # * Date: 25/04/2018
  # * Reviewed By:
  #
  def self.admin_action_types_config
    @ukd_admin_action_types_con ||= {
        GlobalConstant::UserKycDetail.data_mismatch_admin_action_type => 1,
        GlobalConstant::UserKycDetail.document_issue_admin_action_type => 2,
        GlobalConstant::UserKycDetail.other_issue_admin_action_type => 4
    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 25/04/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        admin_action_types: admin_action_types_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern


  def is_re_submitted?
    submission_count.to_i > 1 ? 1 : 0
  end

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

  def check_duplicate_status
    [
        GlobalConstant::UserKycDetail.unprocessed_kyc_duplicate_status,
        GlobalConstant::UserKycDetail.is_kyc_duplicate_status
    ].include?(kyc_duplicate_status)
  end

  def show_duplicate_status
    check_duplicate_status || email_duplicate_status == GlobalConstant::UserKycDetail.yes_email_duplicate_status
  end

  def never_duplicate?

    [
        GlobalConstant::UserKycDetail.unprocessed_kyc_duplicate_status,
        GlobalConstant::UserKycDetail.never_kyc_duplicate_status
    ].include?(self.kyc_duplicate_status) && email_duplicate_status != GlobalConstant::UserKycDetail.yes_email_duplicate_status

  end

  def self.get_cynopsis_user_id(user_id)
    "ts_#{Rails.env[0..1]}_#{user_id}"
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
    UserKycDetail.bulk_flush([self.user_id])
  end

end
