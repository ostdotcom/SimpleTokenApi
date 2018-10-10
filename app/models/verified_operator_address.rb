class VerifiedOperatorAddress < EstablishSimpleTokenContractInteractionsDbConnection

  enum status: {
      GlobalConstant::VerifiedOperatorAddress.unused_status => 0,
      GlobalConstant::VerifiedOperatorAddress.active_status => 1,
      GlobalConstant::VerifiedOperatorAddress.inactive_status => 2
  }

end
