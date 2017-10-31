class SaleGlobalVariable < EstablishSimpleTokenContractInteractionsDbConnection

  enum variable_kind: {
           GlobalConstant::SaleGlobalVariable.sale_ended_variable_kind => 1,
           GlobalConstant::SaleGlobalVariable.last_block_processed_variable_kind => 2
       }

  scope :sale_ended, -> { where(variable_kind: GlobalConstant::SaleGlobalVariable.sale_ended_variable_kind) }
  scope :last_block_processed, -> { where(variable_kind: GlobalConstant::SaleGlobalVariable.last_block_processed_variable_kind) }


end
