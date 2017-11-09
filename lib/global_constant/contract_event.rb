# frozen_string_literal: true
module GlobalConstant

  class ContractEvent

    class << self

      ### Kind Start ###

      def whitelist_kind
        'whitelist'
      end

      def transfer_kind
        'transfer'
      end

      def finalize_kind
        'finalize'
      end

      ### Kind End ###

      ## Status Start ###

      def unprocessed_status
        'unprocessed'
      end

      def processed_status
        'processed'
      end

      ## Status End ###


    end

  end

end
