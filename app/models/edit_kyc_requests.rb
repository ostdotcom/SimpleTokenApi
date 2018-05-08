class EditKycRequests < EstablishSimpleTokenLogDbConnection

  serialize :debug_data

  enum status: {
      GlobalConstant::UserKycDetail.unprocessed_edit_kyc => 0,
      GlobalConstant::UserKycDetail.processed_edit_kyc => 1,
      GlobalConstant::UserKycDetail.failed_edit_kyc => 2,
      GlobalConstant::UserKycDetail.in_process_edit_kyc => 3,
      GlobalConstant::UserKycDetail.unwhitelist_in_process_edit_kyc => 4
  }

  enum update_action: {
      GlobalConstant::UserKycDetail.open_case_update_action => 1,
      GlobalConstant::UserKycDetail.update_ethereum_action => 2
  }

  scope :unprocessed, -> { where(status: GlobalConstant::UserKycDetail.unprocessed_edit_kyc) }

  scope :under_process, -> { where(["status IN (?)", [GlobalConstant::UserKycDetail.unprocessed_edit_kyc,
                                                      GlobalConstant::UserKycDetail.in_process_edit_kyc,
                                                      GlobalConstant::UserKycDetail.unwhitelist_in_process_edit_kyc]])}

end