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
  end

  def process_user_kyc_details
    UserKycDetail.
        where(client_id: @client_id, status: GlobalConstant::UserKycDetail.active_status).
        order({client_id: :desc}).
        find_in_batches(batch_size: 100) do |ukds|

      ukds.each do |ukd|
        if (ukd.admin_status == GlobalConstant::UserKycDetail.unprocessed_admin_status) && (ukd.last_reopened_at.to_i <= 0)
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
            user_extended_details_id: user_extended_details_id
        }
    )
    Rails.logger.info("---- enqueue_job AutoApproveUpdateJob for ued_id-#{user_extended_details_id} done")
  end

end