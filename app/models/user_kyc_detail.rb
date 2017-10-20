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
      GlobalConstant::UserKycDetail.denied_admin_status => 3, # red
      GlobalConstant::UserKycDetail.whitelisted_admin_status => 4 # green
  }

  enum token_sale_participation_phase: {
      GlobalConstant::TokenSale.pre_sale_token_sale_phase => 1,
      GlobalConstant::TokenSale.open_sale_token_sale_phase => 2
  }

  enum duplicate_status: {
      GlobalConstant::UserKycDetail.unprocessed_duplicate_status => 0,
      GlobalConstant::UserKycDetail.never_duplicate_status => 1,
      GlobalConstant::UserKycDetail.is_duplicate_status => 2,
      GlobalConstant::UserKycDetail.was_duplicate_status => 3
  }, _suffix: true

  def cynonpsis_approved_statuses
    [GlobalConstant::UserKycDetail.cleared_cynopsis_status, GlobalConstant::UserKycDetail.approved_cynopsis_status]
  end

  def admin_approved_statuses
    [GlobalConstant::UserKycDetail.qualified_admin_status, GlobalConstant::UserKycDetail.whitelisted_admin_status]
  end

  def kyc_approved?
    cynonpsis_approved_statuses.include?(cynopsis_status) && admin_approved_statuses.include?(admin_status)
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
        GlobalConstant::UserKycDetail.unprocessed_duplicate_status,
        GlobalConstant::UserKycDetail.is_duplicate_status
    ].include?(duplicate_status)

  end

  def never_duplicate?

    [
        GlobalConstant::UserKycDetail.unprocessed_duplicate_status,
        GlobalConstant::UserKycDetail.never_duplicate_status
    ].include?(duplicate_status)

  end

end
