class UserKycDetail < EstablishSimpleTokenUserDbConnection


  enum aml_status: {
      GlobalConstant::UserKycDetail.unprocessed_aml_status => 1, # yello
      GlobalConstant::UserKycDetail.pending_aml_status => 2, # yello
      GlobalConstant::UserKycDetail.cleared_aml_status => 3, # green
      GlobalConstant::UserKycDetail.approved_aml_status => 4, # green
      GlobalConstant::UserKycDetail.rejected_aml_status => 5, # red
      GlobalConstant::UserKycDetail.failed_aml_status => 6 # red
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

  enum status: {
      GlobalConstant::UserKycDetail.active_status => 1,
      GlobalConstant::UserKycDetail.inactive_status => 2
  }, _suffix: true

  scope :kyc_admin_and_aml_approved, -> {where(aml_status: GlobalConstant::UserKycDetail.aml_approved_statuses, admin_status: GlobalConstant::UserKycDetail.admin_approved_statuses)}
  scope :whitelist_status_unprocessed, -> {where(whitelist_status: GlobalConstant::UserKycDetail.unprocessed_whitelist_status)}

  scope :active_kyc, -> {where(status: GlobalConstant::UserKycDetail.active_status)}

  scope :filter_by, -> (filters) {
    where_clause = {}
    where_bitwise_clause = {}
    filters.each do |key, val|
      filter_data = GlobalConstant::UserKycDetail.filters[key.to_s][val.to_s]
      if key.to_s === GlobalConstant::UserKycDetail.admin_action_types_key
        where_bitwise_clause = filter_data
      else
        where_clause[key] = filter_data if filter_data.present?
      end
    end
    where(where_clause).where(where_bitwise_clause)
  }

  scope :sorting_by, -> (sortings) {
    order_clause = {}
    # This sorting is also used in user model.
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

  # Array of Admin action types
  #
  # * Author: Aman
  # * Date: 25/04/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of admin action bits set for user
  #
  def admin_action_types_array
    @admin_action_types_array = UserKycDetail.get_bits_set_for_admin_action_types(admin_action_types)
  end

  # last qualified by admin type
  #
  # * Author: Aman
  # * Date: 25/04/2018
  # * Reviewed By:
  #
  # @returns [String] returns the last qualify type
  #
  def last_qualified_type
    qualify_types_array.include?(GlobalConstant::UserKycDetail.manually_approved_qualify_type) ?
                             GlobalConstant::UserKycDetail.manually_approved_qualify_type : qualify_types_array[0]
  end

  # Array of Qualify types
  #
  # * Author: Aman
  # * Date: 25/04/2018
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of Qualify types bits set for user
  #
  def qualify_types_array
    # puts "qualify_types : #{qualify_types.inspect}"
    @admin_action_types_array = UserKycDetail.get_bits_set_for_qualify_types(qualify_types)
  end

  # Check if case was ever auto approved
  #
  # * Author: Aman
  # * Date: 25/04/2018
  # * Reviewed By:
  #
  # @returns [Boolean] returns true if auto approved bit is set
  #
  def has_been_auto_approved?
    qualify_types_array.include?(GlobalConstant::UserKycDetail.auto_approved_qualify_type)
  end

  # Admin action types config
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

  # qualify type config
  #
  # * Author: Aman
  # * Date: 25/04/2018
  # * Reviewed By:
  #
  def self.qualify_types_config
    @ukd_qualify_types_config_con ||= {
        GlobalConstant::UserKycDetail.auto_approved_qualify_type => 1,
        GlobalConstant::UserKycDetail.manually_approved_qualify_type => 2
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
        admin_action_types: admin_action_types_config,
        qualify_types: qualify_types_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern
  include AttributeParserConcern


  def is_re_submitted?
    submission_count.to_i > 1 ? 1 : 0
  end

  def kyc_approved?
    GlobalConstant::UserKycDetail.aml_approved_statuses.include?(aml_status) && GlobalConstant::UserKycDetail.admin_approved_statuses.include?(admin_status)
  end

  def kyc_denied?
    (aml_status == GlobalConstant::UserKycDetail.rejected_aml_status) || (admin_status == GlobalConstant::UserKycDetail.denied_admin_status)
  end

  def aml_rejected?
    aml_status == GlobalConstant::UserKycDetail.rejected_aml_status
  end

  def case_closed_for_admin?
    (kyc_approved? || kyc_denied?) || GlobalConstant::UserKycDetail.admin_approved_statuses.include?(admin_status)
  end

  def case_closed?
    kyc_approved? || kyc_denied?
  end


  def case_closed_for_auto_approve?
    case_closed? || (last_reopened_at.to_i > 0) ||
        admin_action_types_array.present? || GlobalConstant::UserKycDetail.admin_approved_statuses.include?(admin_status)
  end

  def can_delete?
    !case_closed?
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

  # Whitelist confirmation is pending till kyc_confirmed_at is populated and status is done
  #
  # * Author: Pankaj
  # * Date: 17/05/2018
  #
  def whitelist_confirmation_done?
    (whitelist_status == GlobalConstant::UserKycDetail.done_whitelist_status && kyc_confirmed_at.present?)
  end


  # User Kyc Status
  #
  # * Author: Tejas
  # * Date: 27/09/2018
  # * Reviewed By: Aman
  #
  # @return [String] status of kyc
  #
  def kyc_status
    case true
    when kyc_approved?
      GlobalConstant::UserKycDetail.kyc_approved_status
    when kyc_denied?
      GlobalConstant::UserKycDetail.kyc_denied_status
    when kyc_pending?
      GlobalConstant::UserKycDetail.kyc_pending_status
    else
      fail "Invalid kyc status"
    end
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

  # Set the extra needed data for hashed response
  #
  # * Author: Aman
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def extra_fields_to_set
    {
        kyc_status: self.kyc_status
    }
  end

  # Get
  #
  # * Author: Aman
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def get_last_acted_admin_hash
    admin = nil
    if self.last_acted_by.to_i > 0
      admin = Admin.get_from_memcache(self.last_acted_by)
    end
    admin.present? ? admin.get_hash : {}
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
