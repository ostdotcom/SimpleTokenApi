class RewhitelistJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Tejas
  # * Date: 10/10/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def perform(params)
    init_params(params)

    rewhitelist_users

  end

  private

  # Init params
  #
  # * Author: Tejas
  # * Date: 10/10/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def init_params(params)
    Rails.logger.info("-- init_params params: #{params.inspect}")

    @client_id = params[:client_id]
    @client = Client.get_from_memcache(@client_id)

  end

  # Rewhitelist Users
  #
  # * Author: Tejas
  # * Date: 10/10/2018
  # * Reviewed By:
  #
  # todo: optimize
  #
  def rewhitelist_users
    user_ids = ar_obj.pluck(:user_id)
    return if user_ids.blank?

    ar_obj.update_all(whitelist_status: GlobalConstant::UserKycDetail.unprocessed_whitelist_status)
    ar_obj.bulk_flush(user_ids)
  end

  def ar_obj
    UserKycDetail.using_client_shard(client: @client).active_kyc.where(client_id: @client_id,
                                   whitelist_status: [GlobalConstant::UserKycDetail.failed_whitelist_status, GlobalConstant::UserKycDetail.done_whitelist_status])
  end

end

