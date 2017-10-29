class ContractEvent < EstablishSimpleTokenLogDbConnection

  serialize :data, Hash

  enum kind: {
      GlobalConstant::ContractEvent.whitelist_kind => 1
  }

end
