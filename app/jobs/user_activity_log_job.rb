class UserActivityLogJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By:
  #
  def perform(params)

    init_params(params)

    create_log

  end

  private

  # Init params
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By:
  #
  def init_params(params)
    @user_id = params[:user_id]
    @action = params[:action]
    @action_timestamp = params[:action_timestamp]

    @admin_id = params[:admin_id]
    @extra_data = params[:extra_data]
  end

  # Get Log type
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By:
  #
  def log_type
    GlobalConstant::UserActivityLog.admin_actions.include?(@action) ? GlobalConstant::UserActivityLog.admin_log_type : GlobalConstant::UserActivityLog.developer_log_type
  end

  # Create new user_action_log
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By:
  #
  #
  def create_log
    UserActivityLog.create!(
        user_id: @user_id,
        admin_id: @admin_id,
        log_type: log_type,
        action: @action,
        action_timestamp: @action_timestamp,
        data: @extra_data
    )
  end


end
