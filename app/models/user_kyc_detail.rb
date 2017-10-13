class UserKycDetail < EstablishSimpleTokenUserDbConnection

  enum cynopsis_status: {
    GlobalConstant::UserKycDetail.un_processed_cynopsis_status => 1,
    GlobalConstant::UserKycDetail.cleared_cynopsis_status => 2,
    GlobalConstant::UserKycDetail.pending_cynopsis_status => 3,
    GlobalConstant::UserKycDetail.pending_cynopsis_status => 4,
    GlobalConstant::UserKycDetail.rejected_cynopsis_status => 5
  }

  enum admin_status: {
    GlobalConstant::UserKycDetail.un_processed_admin_status => 1,
    GlobalConstant::UserKycDetail.qualified_admin_status => 2,
    GlobalConstant::UserKycDetail.denied_admin_status => 3,
    GlobalConstant::UserKycDetail.whitelisted_admin_status => 4
  }

  enum token_sale_participation_phase: {
    GlobalConstant::TokenSale.pre_sale_token_sale_phase => 1,
    GlobalConstant::TokenSale.pre_phase_two_token_sale_phase => 2,
    GlobalConstant::TokenSale.open_sale_token_sale_phase => 3
  }

end
