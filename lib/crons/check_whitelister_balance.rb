module Crons

  class CheckWhitelisterBalance

    MIN_ETH_BALANCE = 0.5
    ETH_BALANCE_TO_STOP = 0.0002

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

        r = Request::OpsApi::GetEthBalance.new.perform(ethereum_address: whitelister_address)
        fail "error from ops api - #{r.inspect}" unless r.success?
        eth_value_in_wei = r.data['balance']
        eth_value = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(eth_value_in_wei.to_i).to_f.round(5)
        previous_balance = c_w_o.balance
        c_w_o.balance = eth_value
        c_w_o.save! if c_w_o.changed?

        if eth_value < ETH_BALANCE_TO_STOP && c_w_o.no_suspension_type?
          c_w_o.mark_client_eth_balance_low
          next
        end

        if c_w_o.low_balance_suspension_type? && eth_value > ETH_BALANCE_TO_STOP
          c_w_o.mark_client_whitelist_happening
        end

        send_report_email(c_w_o.client_id, whitelister_address, eth_value) if c_w_o.balance < MIN_ETH_BALANCE &&
            (previous_balance.nil? || previous_balance > MIN_ETH_BALANCE)
        return if GlobalConstant::SignalHandling.sigint_received?

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
    def send_report_email(client_id, whitelister_address, ether_value)

      admin_emails = GlobalConstant::Admin.get_all_admin_emails_for(
          client_id,
          GlobalConstant::Admin.whitelisting_balance_alert_notification_type
      )

      admin_emails.each do |admin_email|
        Email::HookCreator::SendTransactionalMail.new(
            client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
            email: admin_email,
            template_name: GlobalConstant::PepoCampaigns.low_whitelister_balance_template,
            template_vars: {ether_value: ether_value, whitelister_address: whitelister_address}
        ).perform

      end

    end

  end

end