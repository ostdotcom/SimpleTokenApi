class UserActivityLogJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By: Sunil
  #
  def perform(params)

    init_params(params)

    set_encrypted_extra_data

    create_log

  end

  private

  # Init params
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By: Sunil
  #
  def init_params(params)
    @client_id = @params[:client_id]
    @user_id = params[:user_id]
    @action = params[:action]
    @action_timestamp = params[:action_timestamp]

    @admin_id = params[:admin_id]
    @case_id = params[:case_id]
    # NOTE: Called from two places, one time it's hash with indifferent access and another is normal hash
    # so following line is required and can't be changed. Talk to Sunil, before you touch it.
    @extra_data = params[:extra_data].present? ? params[:extra_data].deep_symbolize_keys : nil

    @client = Client.get_from_memcache(@client_id)
    @e_extra_data = nil
  end

  # set encrypted data if present
  #
  # * Author: Aman
  # * Date: 02/11/2017
  # * Reviewed By: Sunil
  #
  # Sets @e_extra_data
  #
  # Note: In case of an error, the log entry should still be there will nil data
  #
  def set_encrypted_extra_data
    return if @extra_data.blank?

    kms_login_client = Aws::Kms.new('entity_association', 'general_access')
    r = kms_login_client.decrypt(GeneralSalt.get_user_activity_logging_salt_type)
    return unless r.success?

    d_salt = r.data[:plaintext]

    r = LocalCipher.new(d_salt).encrypt(@extra_data)
    return unless r.success?

    @e_extra_data = r.data[:ciphertext_blob]
  end

  # Create new user_action_log
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By: Sunil
  #
  def create_log
    UserActivityLog.using_client_shard(client: @client).create!(
        user_id: @user_id,
        admin_id: @admin_id,
        log_type: log_type,
        action: @action,
        action_timestamp: @action_timestamp,
        e_data: @e_extra_data
    )
  end

  # Get Log type
  #
  # * Author: Aman
  # * Date: 21/10/2017
  # * Reviewed By: Sunil
  #
  def log_type
    GlobalConstant::UserActivityLog.admin_actions.include?(@action) ?
        GlobalConstant::UserActivityLog.admin_log_type :
        GlobalConstant::UserActivityLog.developer_log_type
  end

end
