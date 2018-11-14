module Crons

  class RefreshTransactionGasPrice

    # initialize
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [Crons::RefreshTransactionGasPrice]
    #
    def initialize(params={})
    end

    # perform
    #
    # * Author: Pankaj
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # Refresh gas price from EthGasStation
    #
    def perform

      (0...10).each do |i|
        break if EstimatedGasPrice::CurrentPrice.new.refresh

        sleep(2)

        ApplicationMailer.notify(
            body: "Gas price is not updated, tried 10 times every 2 seconds",
            subject: "Exception in Refreshing gas price from eth gas station"
        ).deliver if i == 9

        return if GlobalConstant::SignalHandling.sigint_received?
      end

    end

  end

end