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

    create_user_utm_log

    fetch_duplicate_email_data

    insert_email_dupliacte_logs if @duplicate_user_ids.present?

    UserActivityLogJob.new().perform({
                                         user_id: @user.id,
                                         action: GlobalConstant::UserActivityLog.register_action,
                                         action_timestamp: Time.now.to_i
                                     })
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
    @user = User.where(id: @user_id).first
    @utm_params = params[:utm_params] || {}
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

    @duplicate_user_ids = User.where("email like ?", email_regex).pluck(:id)
    @duplicate_user_ids.delete(@user_id)
  end

  # Fire bulk update
  #
  # * Author: Aman
  # * Date: 20/10/2017
  # * Reviewed By: Sunil
  #
  def insert_email_dupliacte_logs
    current_time = Time.now.to_s(:db)
    status_int = ::UserEmailDuplicationLog.statuses[GlobalConstant::UserEmailDuplicationLog.active_status]
    sql_data = []

    @duplicate_user_ids.each do |d_user_id|
      sql_data << "(#{@user_id}, #{d_user_id},  #{status_int}, '#{current_time}', '#{current_time}')"
    end

    UserEmailDuplicationLog.bulk_insert(sql_data)
  end


end
