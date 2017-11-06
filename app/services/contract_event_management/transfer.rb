module ContractEventManagement

  class Transfer < Base

    def initialize(params)
      super
    end

    def perform
      super
    end



    def event_kind
      GlobalConstant::ContractEvent.transfer_kind
    end


  end

end