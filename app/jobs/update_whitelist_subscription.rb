class UpdateWhitelistSubscription < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Aniket
  # * Date: 07/08/2018
  # * Reviewed By:
  #
  def perform(params)
    contract_addresses = ClientWhitelistDetail.get_active_contract_addressess
    Request::OpsApi::UpdateSubscription.new.perform({contract_addresses: contract_addresses})
  end

end
