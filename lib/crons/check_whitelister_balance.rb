module Crons

  class CheckWhitelisterBalance

    MIN_ETH_BALANCE = 2

    # initialize
    #
    # * Author: Aman
    # * Date: 05/01/2018
    # * Reviewed By:
    #
    # @return [Crons::CheckWhitelisterBalance]
    #
    def initialize(params={})
    end

    # perform
    #
    # * Author: Aman
    # * Date: 05/01/2018
    # * Reviewed By:
    #
    #check whitelister address eth balance
    #
    def perform
      @whitelister_address = GlobalConstant::TokenSale.whitelister_address
      r = OpsApi::Request::GetEthBalance.new.perform(ethereum_address: @whitelister_address)
      fail "error from ops api - #{r.inspect}" unless r.success?
      eth_value_in_wei = r.data['balance']

      @eth_value = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(eth_value_in_wei.to_i).to_f.round(2)

      if @eth_value <= MIN_ETH_BALANCE
        initiate_fund_transfer
        send_report_email
      end

    end

    private

    # initiate_fund_transfer to whitelister
    #
    # * Author: Aman
    # * Date: 05/01/2018
    # * Reviewed By:
    #
    # transfer fund to whitelister
    #
    def initiate_fund_transfer
      r = OpsApi::Request::TransferEther.new.transfer(ethereum_address: @whitelister_address)
      fail "error from ops api - #{r.inspect}" unless r.success?
      @transaction_hash = r.data['transaction_hash']
    end

    # send email to admin for balance of whitelister
    #
    # * Author: Aman
    # * Date: 05/01/2018
    # * Reviewed By:
    #
    # check whitelister address eth balance
    #
    def send_report_email
      ApplicationMailer.notify(
          to: GlobalConstant::Email.default_to,
          body: 'Ether was low. Fund transfer initiated for whitelister address',
          data: {eth_value: @eth_value, transaction_hash: @transaction_hash},
          subject: 'KYCaaS Whitelist Ether Balance Transfer Started'
      ).deliver
    end

  end

end