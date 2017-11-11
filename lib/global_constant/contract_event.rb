# frozen_string_literal: true
module GlobalConstant

  class ContractEvent

    class << self

      ### Kind Start ###


      def admin_address_changed_kind
        'AdminAddressChanged'
      end

      def allocation_granted_kind
        'AllocationGranted'
      end

      def allocation_processed_kind
        'AllocationProcessed'
      end

      def allocation_revoked_kind
        'AllocationRevoked'
      end

      def approval_kind
        'Approval'
      end

      def burnt_kind
        'Burnt'
      end

      def finalized_kind
        'Finalized'
      end

      def grantable_allocation_added_kind
        'GrantableAllocationAdded'
      end

      def grantable_allocation_granted_kind
        'GrantableAllocationGranted'
      end

      def initialized_kind
        'Initialized'
      end

      def locked_kind
        'Locked'
      end

      def ops_address_changed_kind
        'OpsAddressChanged'
      end

      def ownership_transfer_completed_kind
        'OwnershipTransferCompleted'
      end

      def ownership_transfer_initiated_kind
        'OwnershipTransferInitiated'
      end

      def pause_kind
        'Pause'
      end

      def phase1_account_tokens_max_updated_kind
        'Phase1AccountTokensMaxUpdated'
      end

      def presale_added_kind
        'PresaleAdded'
      end

      def presale_added_to_token_sale_kind
        'PresaleAddedToTokenSale'
      end

      def revoke_address_changed_kind
        'RevokeAddressChanged'
      end

      def tokens_per_k_ether_updated_kind
        'TokensPerKEtherUpdated'
      end

      def tokens_purchased_kind
        'TokensPurchased'
      end

      def tokens_reclaimed_kind
        'TokensReclaimed'
      end

      def tokens_transferred_kind
        'TokensTransferred'
      end

      def transfer_kind
        'Transfer'
      end

      def unlock_date_extended_kind
        'UnlockDateExtended'
      end

      def unpause_kind
        'Unpause'
      end

      def unsold_tokens_burnt_kind
        'UnsoldTokensBurnt'
      end

      def wallet_changed_kind
        'WalletChanged'
      end

      def whitelist_updated_kind
        'WhitelistUpdated'
      end

      def processable_allocation_added_kind
        'ProcessableAllocationAdded'
      end

      def processable_allocation_processed_kind
        'ProcessableAllocationProcessed'
      end


      ### Kind End ###

      ## Status Start ###

      def recorded_status
        'recorded'
      end

      def processed_status
        'processed'
      end

      def failed_status
        'failed'
      end

      def duplicate_status
        'duplicate'
      end

      ## Status End ###


    end

  end

end
