class UserContractEvent < EstablishSimpleTokenLogDbConnection

  enum kind: {
             GlobalConstant::UserContractEvent.whitelist_kind => 1
        }, _suffix: true

end
