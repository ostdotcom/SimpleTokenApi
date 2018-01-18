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
      ClientWhitelistDetail.where(status: GlobalConstant::ClientWhitelistDetail.active_status).all.each do |c_w_o|
        whitelister_address = c_w_o.whitelister_address

        r = OpsApi::Request::GetEthBalance.new.perform(ethereum_address: whitelister_address)
        fail "error from ops api - #{r.inspect}" unless r.success?
        eth_value_in_wei = r.data['balance']
        eth_value = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(eth_value_in_wei.to_i).to_f.round(2)

        send_report_email(c_w_o.client_id, whitelister_address, eth_value) if eth_value <= MIN_ETH_BALANCE
      end

    end

    private

    # send email to admin for balance of whitelister
    #
    # * Author: Aman
    # * Date: 05/01/2018
    # * Reviewed By:
    #
    # check whitelister address eth balance
    #
    def send_report_email(client_id, whitelister_address, eth_value)
      ApplicationMailer.notify(
          to: GlobalConstant::Email.default_to,
          body: 'Ether Balance is low for whitelister. Please Transfer Ether',
          data: {eth_value: eth_value, whitelister_address: whitelister_address, client_id: client_id},
          subject: 'KYCaaS Whitelister Ether Balance is low'
      ).deliver
    end

  end

end