class EditKycRequests < EstablishSimpleTokenLogDbConnection

  serialize :debug_data

  enum status: {
      GlobalConstant::UserKycDetail.unprocessed_edit_kyc => 0,
      GlobalConstant::UserKycDetail.processed_edit_kyc => 1,
      GlobalConstant::UserKycDetail.failed_edit_kyc => 2
  }

  scope :unprocessed, -> { where(status: GlobalConstant::UserKycDetail.unprocessed_edit_kyc) }

end