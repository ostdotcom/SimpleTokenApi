class NewUserRegisterJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Aman
  # * Date: 20/10/2017
  # * Reviewed By: Sunil
  #
  def perform(params)

    init_params(params)

    create_email_service_api_call_hook if @client.is_st_token_sale_client?

    fetch_duplicate_email_data

    create_email_duplicate_logs if @duplicate_user_ids.present?

    UserActivityLogJob.new().perform({
                                         client_id: @client_id,
                                         user_id: @user.id,
                                         action: GlobalConstant::UserActivityLog.register_action,
                                         action_timestamp: Time.now.to_i,
                                         extra_data: {
                                             browser_user_agent: @browser_user_agent,
                                             geoip_country: @geoip_country
                                         }
                                     })

    WebhookJob::RecordEvent.perform_now(@event)
  end

  private

  # Init params
  #
  # * Author: Aman
  # * Date: 20/10/2017
  # * Reviewed By: Sunil
  #
  def init_params(params)
    @client_id = params[:client_id]
    @user_id = params[:user_id]
    @browser_user_agent = params[:browser_user_agent]
    @geoip_country = params[:geoip_country]
    @event = params[:event]

    @client = Client.get_from_memcache(@client_id)

    @user = User.using_client_shard(client: @client).where(id: @user_id).first
    @duplicate_user_ids = []
  end


  # Create Hook to sync data in Email Service
  #
  # * Author: Puneet
  # * Date: 03/11/2017
  # * Reviewed By: Sunil
  #
  def create_email_service_api_call_hook

    Email::HookCreator::AddContact.new(
        client_id: @client.id,
        email: @user.email,
        custom_attributes: {
            GlobalConstant::PepoCampaigns.token_sale_registered_attribute => GlobalConstant::PepoCampaigns.token_sale_registered_value
        },
        list_id: GlobalConstant::PepoCampaigns.master_list_id
    ).perform

  end

  # Fetch users with similar emails
  #
  # * Author: Aman
  # * Date: 20/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @duplicate_user_ids
  #
  def fetch_duplicate_email_data
    split_parts = @user.email.split(/[+@]/)
    email_name = split_parts.first
    email_domain = split_parts.last

    email_regex = "#{email_name}%@#{email_domain}"

    @duplicate_user_ids = User.using_client_shard(client: @client).where(client_id: @client_id).where("email like ?", email_regex).pluck(:id)
    @duplicate_user_ids.delete(@user_id)
  end

  # Fire bulk update
  #
  # * Author: Aman
  # * Date: 20/10/2017
  # * Reviewed By: Sunil
  #
  def create_email_duplicate_logs
    current_time = Time.now.to_s(:db)
    status_int = ::UserEmailDuplicationLog.using_client_shard(client: @client).
        statuses[GlobalConstant::UserEmailDuplicationLog.active_status]
    sql_data = []

    @duplicate_user_ids.each do |d_user_id|
      sql_data << "(#{@user_id}, #{d_user_id},  #{status_int}, '#{current_time}', '#{current_time}')"
    end

    UserEmailDuplicationLog.using_client_shard(client: @client).bulk_insert(sql_data)
  end


end
