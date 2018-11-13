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

    create_user_utm_log if @utm_params.present?

    create_email_service_api_call_hook if @client.is_st_token_sale_client?

    fetch_duplicate_email_data

    create_email_duplicate_logs if @duplicate_user_ids.present?

    UserActivityLogJob.new().perform({
                                         user_id: @user.id,
                                         action: GlobalConstant::UserActivityLog.register_action,
                                         action_timestamp: Time.now.to_i,
                                         extra_data: {
                                             ip_address: @ip_address,
                                             browser_user_agent: @browser_user_agent,
                                             geoip_country: @geoip_country
                                         }
                                     })

    RecordEventJob.perform_now(@event)
  end

  private

  # Init params
  #
  # * Author: Aman
  # * Date: 20/10/2017
  # * Reviewed By: Sunil
  #
  def init_params(params)
    @user_id = params[:user_id]
    @ip_address= params[:ip_address]
    @browser_user_agent = params[:browser_user_agent]
    @geoip_country = params[:geoip_country]
    @utm_params = params[:utm_params] || {}
    @event = params[:event]

    @user = User.where(id: @user_id).first
    @client_id = @user.client_id
    @client = Client.get_from_memcache(@client_id)
    @duplicate_user_ids = []
  end

  # Create User Utm Log
  #
  # * Author: Aman
  # * Date: 23/10/2017
  # * Reviewed By: Sunil
  #
  #
  def create_user_utm_log
    # Todo: return if @utm_params.blank?

    u_utm_log = UserUtmLog.new(user_id: @user_id)
    u_utm_log.origin_page= @utm_params['origin_page'].to_s
    u_utm_log.utm_type= @utm_params['utm_type'].to_s
    u_utm_log.utm_medium= @utm_params['utm_medium'].to_s
    u_utm_log.utm_source= @utm_params['utm_source'].to_s
    u_utm_log.utm_term= @utm_params['utm_term'].to_s
    u_utm_log.utm_content= @utm_params['utm_content'].to_s
    u_utm_log.utm_campaign = @utm_params['utm_campaign'].to_s
    u_utm_log.save!(validate: false)
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

    @duplicate_user_ids = User.where(client_id: @client_id).where("email like ?", email_regex).pluck(:id)
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
    status_int = ::UserEmailDuplicationLog.statuses[GlobalConstant::UserEmailDuplicationLog.active_status]
    sql_data = []

    @duplicate_user_ids.each do |d_user_id|
      sql_data << "(#{@user_id}, #{d_user_id},  #{status_int}, '#{current_time}', '#{current_time}')"
    end

    UserEmailDuplicationLog.bulk_insert(sql_data)
  end


end
