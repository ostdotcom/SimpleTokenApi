class ReprocessKycAutoApproveJob < ApplicationJob
  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  def perform(params)
    init_params(params)
    process_user_kyc_details
  end

  private

  # Init params
  #
  # * Author: Aniket
  # * Date: 06/07/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  #
  # Sets @client_id
  #
  def init_params(parmas)
    @client_id = parmas[:client_id]
    @client = Client.get_from_memcache(@client_id)
  end

  # Trigger auto_approve_update rescue task for users
  #
  # * Author: Tejas
  # * Date: 12/07/2018
  # * Reviewed By:
  #
  def process_user_kyc_details
    UserKycDetail.using_client_shard(client: @client).
        where(client_id: @client_id,
              status: GlobalConstant::UserKycDetail.active_status,
              admin_status: GlobalConstant::UserKycDetail.unprocessed_admin_status).
        order({client_id: :desc}).
        find_in_batches(batch_size: 100) do |ukds|

      ukds.each do |ukd|
        if (!ukd.has_been_auto_approved?)
          trigger_auto_approve_update_rescue_task(ukd.user_extended_detail_id)
        end
      end

    end
  end

  # Trigger auto approve update rescue task
  #
  # * Author: Aniket
  # * Date: 06/07/2018
  # * Reviewed By:
  #
  def trigger_auto_approve_update_rescue_task(user_extended_details_id)
    BgJob.enqueue(
        AutoApproveUpdateJob,
        {
            client_id: @client_id,
            reprocess: 1,
            user_extended_details_id: user_extended_details_id
        }
    )
    Rails.logger.info("---- enqueue_job AutoApproveUpdateJob for ued_id-#{user_extended_details_id} done")
  end

end
