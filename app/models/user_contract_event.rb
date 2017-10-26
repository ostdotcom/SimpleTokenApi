class UserContractEvent < EstablishSimpleTokenLogDbConnection

  enum kind: {
      GlobalConstant::UserContractEvent.whitelist_kind => 1
  }

end
