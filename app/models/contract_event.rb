class ContractEvent < EstablishSimpleTokenContractInteractionsDbConnection

  serialize :data, Hash

  enum kind: {

       GlobalConstant::ContractEvent.admin_address_changed_kind => 1,

       GlobalConstant::ContractEvent.allocation_granted_kind => 2,

       GlobalConstant::ContractEvent.allocation_processed_kind => 3,

       GlobalConstant::ContractEvent.allocation_revoked_kind => 4,

       GlobalConstant::ContractEvent.approval_kind => 5,

       GlobalConstant::ContractEvent.burnt_kind => 6,

       GlobalConstant::ContractEvent.finalized_kind => 7,

       GlobalConstant::ContractEvent.grantable_allocation_added_kind => 8,

       GlobalConstant::ContractEvent.grantable_allocation_granted_kind => 9,

       GlobalConstant::ContractEvent.initialized_kind => 10,

       GlobalConstant::ContractEvent.locked_kind => 11,

       GlobalConstant::ContractEvent.ops_address_changed_kind => 12,

       GlobalConstant::ContractEvent.ownership_transfer_completed_kind => 13,

       GlobalConstant::ContractEvent.ownership_transfer_initiated_kind => 14,

       GlobalConstant::ContractEvent.pause_kind => 15,

       GlobalConstant::ContractEvent.phase1_account_tokens_max_updated_kind => 16,

       GlobalConstant::ContractEvent.presale_added_kind => 17,

       GlobalConstant::ContractEvent.presale_added_to_token_sale_kind => 18,

       GlobalConstant::ContractEvent.revoke_address_changed_kind => 19,

       GlobalConstant::ContractEvent.tokens_per_k_ether_updated_kind => 20,

       GlobalConstant::ContractEvent.tokens_purchased_kind => 21,

       GlobalConstant::ContractEvent.tokens_reclaimed_kind => 22,

       GlobalConstant::ContractEvent.tokens_transferred_kind => 23,

       GlobalConstant::ContractEvent.transfer_kind => 24,

       GlobalConstant::ContractEvent.unlock_date_extended_kind => 25,

       GlobalConstant::ContractEvent.unpause_kind => 26,

       GlobalConstant::ContractEvent.unsold_tokens_burnt_kind => 27,

       GlobalConstant::ContractEvent.wallet_changed_kind => 28,

       GlobalConstant::ContractEvent.whitelist_updated_kind => 29,

       GlobalConstant::ContractEvent.processable_allocation_added_kind => 30,

       GlobalConstant::ContractEvent.processable_allocation_processed_kind => 31

   }, _suffix: true

  enum status: {
            GlobalConstant::ContractEvent.recorded_status => 0,
            GlobalConstant::ContractEvent.processed_status => 1,
            GlobalConstant::ContractEvent.failed_status => 2,
            GlobalConstant::ContractEvent.duplicate_status => 3
        }, _suffix: true
end
