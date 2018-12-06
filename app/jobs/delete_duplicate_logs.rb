class DeleteDuplicateLogs < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def perform(params)
    init_params(params)

    # delete user utm data if present
    UserUtmLog.where(user_id: @user_id).delete_all

    fetch_user_details

    unset_user_email_duplicates

    WebhookJob::RecordEvent.perform_now(@event)
    return if @user_kyc_detail.blank?

    fetch_existing_duplicate_data
    update_duplicate_logs_to_inactive
    unset_kyc_duplicate_status_of_previous_users
  end

  private

  # Initialize
  #
  # * Author: Aman
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  # @params [Integer] user_id (mandatory) - user_id of deleted user
  #
  # @return [DeleteDuplicates]
  #
  def init_params(params)
    @user_id = params[:user_id]
    @event = params[:event]

    @client_id, @user, @user_kyc_detail = nil, nil, nil

    @duplicate_kyc_log_ids, @duplicate_kyc_user_ids = [], []
  end

  # Fetch user details
  #
  # * Author: aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @user, @client_id, @user_kyc_detail
  #
  def fetch_user_details
    @user = User.where(id: @user_id).first
    @client_id = @user.client_id
    @user_kyc_detail = UserKycDetail.where(user_id: @user_id).first
  end

  # Mark email duplication logs as inactive and change email duplication status in user_kyc_details
  #
  # * Author: aman
  # * Date: 18/10/2018
  # * Reviewed By:
  #
  #
  def unset_user_email_duplicates
    duplicate_email_user_ids = []
    # fetch as user1
    duplicate_email_user_ids += UserEmailDuplicationLog.where(
        user1_id: @user_id,
        status: GlobalConstant::UserEmailDuplicationLog.active_status
    ).pluck(:user2_id)

    # fetch as user2
    duplicate_email_user_ids += UserEmailDuplicationLog.where(
        user2_id: @user_id,
        status: GlobalConstant::UserEmailDuplicationLog.active_status
    ).pluck(:user1_id)

    return if duplicate_email_user_ids.blank?

    UserEmailDuplicationLog.where(
        user1_id: @user_id,
        status: GlobalConstant::UserEmailDuplicationLog.active_status
    ).update_all(status: GlobalConstant::UserEmailDuplicationLog.inactive_status,
                 updated_at: current_time)

    UserEmailDuplicationLog.where(
        user2_id: @user_id,
        status: GlobalConstant::UserEmailDuplicationLog.active_status
    ).update_all(updated_at: current_time,
                 status: GlobalConstant::UserEmailDuplicationLog.inactive_status)

    duplicate_email_user_ids_with_kyc_done = UserKycDetail.where(
        client_id: @client_id,
        user_id: duplicate_email_user_ids,
        status: GlobalConstant::UserKycDetail.active_status
    ).pluck(:user_id)

    return if duplicate_email_user_ids_with_kyc_done.blank?


    email_duplicate_data = {}

    UserEmailDuplicationLog.where(
        user1_id: duplicate_email_user_ids_with_kyc_done,
        status: GlobalConstant::UserEmailDuplicationLog.active_status
    ).all.each do |u_e_d_log|
      email_duplicate_data[u_e_d_log.user2_id] ||= []
      email_duplicate_data[u_e_d_log.user2_id] << u_e_d_log.user1_id
    end


    UserEmailDuplicationLog.where(
        user2_id: duplicate_email_user_ids_with_kyc_done,
        status: GlobalConstant::UserEmailDuplicationLog.active_status
    ).all.each do |u_e_d_log|
      email_duplicate_data[u_e_d_log.user1_id] ||= []
      email_duplicate_data[u_e_d_log.user1_id] << u_e_d_log.user2_id
    end

    new_email_duplicate_user_ids = []

    if email_duplicate_data.present?
      all_user_ids = email_duplicate_data.keys

      all_user_ids_with_kyc = UserKycDetail.where(
          client_id: @client_id,
          user_id: all_user_ids,
          status: GlobalConstant::UserKycDetail.active_status
      ).pluck(:user_id)

      all_user_ids_with_kyc.map {|x| new_email_duplicate_user_ids += email_duplicate_data[x]}
      new_email_duplicate_user_ids.uniq!
    end

    user_ids_not_email_duplicate_with_kyc_done = duplicate_email_user_ids_with_kyc_done - new_email_duplicate_user_ids

    return if user_ids_not_email_duplicate_with_kyc_done.blank?

    UserKycDetail.where(
        client_id: @client_id,
        user_id: user_ids_not_email_duplicate_with_kyc_done,
        email_duplicate_status: GlobalConstant::UserKycDetail.yes_email_duplicate_status
    ).update_all(
        email_duplicate_status: GlobalConstant::UserKycDetail.no_email_duplicate_status,
        updated_at: current_time
    )

    UserKycDetail.bulk_flush(user_ids_not_email_duplicate_with_kyc_done)
  end

  # Fetch user details
  #
  # * Author: aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @duplicate_kyc_log_ids, @duplicate_kyc_user_ids
  #
  def fetch_existing_duplicate_data
    # fetch as user1
    UserKycDuplicationLog.where(user1_id: @user_id).non_deleted.all.each do |d_log|
      @duplicate_kyc_log_ids << d_log.id
      @duplicate_kyc_user_ids << d_log.user2_id
    end
    # fetch as user2
    UserKycDuplicationLog.where(user2_id: @user_id).non_deleted.all.each do |d_log|
      @duplicate_kyc_log_ids << d_log.id
      @duplicate_kyc_user_ids << d_log.user1_id
    end
    @duplicate_kyc_user_ids.uniq!
  end

  # Update existing kyc details duplicate to inactive
  #
  # * Author: aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def update_duplicate_logs_to_inactive
    UserKycDuplicationLog.where(id: @duplicate_kyc_log_ids).update_all(
        status: GlobalConstant::UserKycDuplicationLog.deleted_status,
        updated_at: current_time
    )
  end

  # Unset existing other's duplicates to inactive
  #
  # * Author: aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  def unset_kyc_duplicate_status_of_previous_users
    dup_active_user_ids = []
    # only current active user_extended_details_id will be with active status
    dup_active_user_ids += UserKycDuplicationLog.where(
        user1_id: @duplicate_kyc_user_ids,
        status: GlobalConstant::UserKycDuplicationLog.active_status
    ).pluck(:user1_id)

    dup_active_user_ids += UserKycDuplicationLog.where(
        user2_id: @duplicate_kyc_user_ids,
        status: GlobalConstant::UserKycDuplicationLog.active_status
    ).pluck(:user2_id)

    dup_active_user_ids.uniq!

    filtered_non_active_duplicate_user_ids = @duplicate_kyc_user_ids - dup_active_user_ids

    return if filtered_non_active_duplicate_user_ids.blank?

    non_active_user_ids_extended_detail = UserKycDetail.where(
        user_id: filtered_non_active_duplicate_user_ids,
        status: GlobalConstant::UserKycDetail.active_status
    ).pluck(:user_extended_detail_id)


    dup_inactive_user_ids = []
    dup_inactive_user_ids += UserKycDuplicationLog.where(
        user1_id: filtered_non_active_duplicate_user_ids,
        user_extended_details1_id: non_active_user_ids_extended_detail,
        status: GlobalConstant::UserKycDuplicationLog.inactive_status
    ).pluck(:user1_id)

    dup_inactive_user_ids += UserKycDuplicationLog.where(
        user2_id: filtered_non_active_duplicate_user_ids,
        user_extended_details2_id: non_active_user_ids_extended_detail,
        status: GlobalConstant::UserKycDuplicationLog.inactive_status
    ).pluck(:user2_id)

    dup_inactive_user_ids.uniq!

    filtered_never_duplicate_user_ids = filtered_non_active_duplicate_user_ids - dup_inactive_user_ids

    UserKycDetail.where(
        user_id: filtered_never_duplicate_user_ids,
        user_extended_detail_id: non_active_user_ids_extended_detail
    ).where.not(kyc_duplicate_status: GlobalConstant::UserKycDetail.never_kyc_duplicate_status).update_all(
        kyc_duplicate_status: GlobalConstant::UserKycDetail.never_kyc_duplicate_status,
        updated_at: current_time
    )

    UserKycDetail.bulk_flush(filtered_never_duplicate_user_ids)

    return if dup_inactive_user_ids.blank?

    UserKycDetail.where(
        user_id: dup_inactive_user_ids,
        user_extended_detail_id: non_active_user_ids_extended_detail,
        kyc_duplicate_status: GlobalConstant::UserKycDetail.is_kyc_duplicate_status
    ).update_all(
        kyc_duplicate_status: GlobalConstant::UserKycDetail.was_kyc_duplicate_status,
        updated_at: current_time
    )

    UserKycDetail.bulk_flush(dup_inactive_user_ids)
  end

  # Get current time in string
  #
  # * Author: aman
  # * Date: 15/10/2017
  # * Reviewed By: Sunil
  #
  # @return [String]
  #
  def current_time
    @current_time ||= Time.now.to_s(:db)
  end

end