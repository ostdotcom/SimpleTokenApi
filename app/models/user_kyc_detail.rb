class UserKycDetail < EstablishSimpleTokenUserDbConnection

  enum cynopsis_status: {
           GlobalConstant::UserKycDetail.un_processed_cynopsis_status => 1, # yello
           GlobalConstant::UserKycDetail.cleared_cynopsis_status => 2, # green
           GlobalConstant::UserKycDetail.pending_cynopsis_status => 3, # yello
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
           GlobalConstant::TokenSale.pre_phase_two_token_sale_phase => 2,
           GlobalConstant::TokenSale.open_sale_token_sale_phase => 3
       }

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

  def kyc_pending?
    !kyc_approved? && !kyc_denied?
  end

end
