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
