class EditKycRequests < EstablishSimpleTokenLogDbConnection

  serialize :debug_data

  enum status: {
      GlobalConstant::EditKycRequest.unprocessed_status => 0,
      GlobalConstant::EditKycRequest.processed_status => 1,
      GlobalConstant::EditKycRequest.failed_status => 2,
      GlobalConstant::EditKycRequest.in_process_status => 3,
      GlobalConstant::EditKycRequest.unwhitelist_in_process_status => 4
  }

  enum update_action: {
      GlobalConstant::EditKycRequest.open_case_update_action => 1,
      GlobalConstant::EditKycRequest.update_ethereum_action => 2
  }

  scope :unprocessed, -> { where(status: GlobalConstant::EditKycRequest.unprocessed_status) }

  scope :under_process, -> { where(status: [GlobalConstant::EditKycRequest.unprocessed_status,
                                                      GlobalConstant::EditKycRequest.in_process_status,
                                                      GlobalConstant::EditKycRequest.unwhitelist_in_process_status])}

end