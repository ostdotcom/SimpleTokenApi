class KycSubmitJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # @param [Hash] params
  #
  def perform(params)
    init_params(params)

    # do not process if kyc was resubmitted
    return if @user_extended_detail_id != @user_kyc_detail.user_extended_detail_id

    block_kyc_submit_job_hard_check

    check_duplicate_kyc_documents

    add_kyc_comparison_details

    UserActivityLogJob.new().perform({
                                         client_id: @client_id,
                                         user_id: @user_id,
                                         action: @action,
                                         action_timestamp: @action_timestamp
                                     })

    WebhookJob::RecordEvent.perform_now(@event.merge!(event_data: event_data))
  end

  private

  # Init params
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # @param [Hash] params
  #
  def init_params(params)
    # Rails.logger.info("-- init_params params: #{params.inspect}")
    @client_id = @params[:client_id]
    @user_id = params[:user_id].to_i
    @user_extended_detail_id = params[:user_extended_detail_id]
    @action = params[:action]
    @action_timestamp = params[:action_timestamp]
    @event = params[:event]

    @client = Client.get_from_memcache(@client_id)

    @user = User.using_client_shard(client: @client).find(@user_id)
    @user_extended_detail = UserExtendedDetail.using_client_shard(client: @client).find(@user_extended_detail_id)
    @user_kyc_detail = UserKycDetail.using_client_shard(client: @client).get_from_memcache(@user_id)

    Rails.logger.info("-- init_params @user_extended_detail: #{@user_extended_detail.id}")
  end

  # Block kyc hard check
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def block_kyc_submit_job_hard_check

    if (@user_kyc_detail.kyc_approved? || @user_kyc_detail.kyc_denied?)
      fail "KYC is already approved for user id: #{@user_id}."
    end

    if @user.id != @user_extended_detail.user_id
      fail "KYC doesn't belong to user id: #{@user_id}."
    end

    Rails.logger.info('-- block_kyc_submit_job_hard_check done')
  end

  ########################## Duplicate KYC handling ##########################

  # Check for duplicate KYC details
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  #
  def check_duplicate_kyc_documents
    Rails.logger.info('-- check_duplicate_kyc_documents')
    r = AdminManagement::Kyc::CheckDuplicates.new({client: @client, user_id: @user_id}).perform
    return r unless r.success?

    @user_kyc_detail.reload
  end


  ########################## OCR FR Job Entry ##########################

  # Make entry to user kyc comparison details for image processing and comparisons
  #
  # * Author: Pankaj
  # * Date: 02/07/2018
  # * Reviewed By:
  #
  def add_kyc_comparison_details
    UserKycComparisonDetail.using_client_shard(client: @client).create!(
        user_extended_detail_id: @user_extended_detail.id,
        client_id: @user_kyc_detail.client_id,
        image_processing_status: GlobalConstant::ImageProcessing.unprocessed_image_process_status
    )
  end

  # event data for webhooks
  #
  # * Author: Tejas
  # * Date: 16/10/2018
  # * Reviewed By: Aman
  #
  def event_data
    {
        user_kyc_detail: @user_kyc_detail.get_hash,
        admin: @user_kyc_detail.get_last_acted_admin_hash
    }
  end

end

