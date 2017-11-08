module ContractEventManagement

  class Transfer < Base

    # initialize
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [ContractEventManagement::Transfer]
    #
    def initialize(params)
      super
    end

    # Perform
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def perform
      super
    end

    # Event kind for contract event row
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [String]
    #
    def event_kind
      GlobalConstant::ContractEvent.transfer_kind
    end

  end

end