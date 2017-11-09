class ContractEvent < EstablishSimpleTokenContractInteractionsDbConnection

  serialize :data, Hash

  enum kind: {
             GlobalConstant::ContractEvent.whitelist_kind => 1,
             GlobalConstant::ContractEvent.transfer_kind => 2,
             GlobalConstant::ContractEvent.finalize_kind => 3
         }, _suffix: true

  enum status: {
          GlobalConstant::ContractEvent.recorded_status => 0,
          GlobalConstant::ContractEvent.processed_status => 1,
          GlobalConstant::ContractEvent.failed_status => 2,
          GlobalConstant::ContractEvent.duplicate_status => 3
      }, _suffix: true
end
