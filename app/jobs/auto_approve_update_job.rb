class AutoApproveUpdateJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue


  # perform
  #
  # * Author: Aniket
  # * Date: 06/07/2018
  # * Reviewed By:
  #
  # @param [Integer] user_extended_details_id - user extended details id
  #
  #
  def perform(params)
    # manual auto approve should never call this job
    init_params(params)

    r = fetch_and_validate_models
    return if !r

    compute_auto_approval

    failed_reason_count = (@user_kyc_comparison_detail.auto_approve_failed_reasons_array &
        GlobalConstant::KycAutoApproveFailedReason.auto_approve_fail_reasons).count

    if failed_reason_count == 0 && @client_kyc_pass_setting.approve_type == GlobalConstant::ClientKycPassSetting.auto_approve_type
      # qualify service call
      qualify_params = {
          id: @user_kyc_detail.id,
          admin_id: Admin::AUTO_APPROVE_ADMIN_ID,
          client_id: @user_kyc_detail.client_id,
          is_auto_approve: true
      }

      service_response = AdminManagement::Kyc::AdminAction::Qualify.new(qualify_params).perform

      ApplicationMailer.notify(
          body: 'Unable to Auto Approve a valid case',
          data: {
              user_extended_detail_id: @user_extended_detail_id,
              user_kyc_comparison_detail_id: @user_kyc_comparison_detail.id
          },
          subject: 'Unable to Auto Approve a valid case'
      ).deliver if !service_response.success?

    end

    @user_kyc_comparison_detail.client_kyc_pass_settings_id = @client_kyc_pass_setting.id
    @user_kyc_comparison_detail.save!
  end

  private

  # Init params
  #
  # * Author: Aniket
  # * Date: 06/07/2018
  # * Reviewed By:
  #
  # @param [Integer] user_extended_details_id - user extended details id
  #
  # Sets @user_extended_detail_id
  #
  def init_params(parmas)
    @user_extended_detail_id = parmas[:user_extended_details_id]
  end

  # Fetch required models
  #
  # * Author: Aniket
  # * Date: 11/07/2018
  # * Reviewed By:
  #
  # Sets @user_kyc_comparison_detail, @user_kyc_detail, @client_token_sale_detail, @client_kyc_pass_setting, @user_extended_detail
  #
  def fetch_and_validate_models
    @user_kyc_comparison_detail = UserKycComparisonDetail.where(user_extended_detail_id: @user_extended_detail_id).first

    if @user_kyc_comparison_detail.blank?
      ApplicationMailer.notify(
          body: 'user kyc comparison details not available',
          data: {user_extended_detail_id: @user_extended_detail_id},
          subject: 'user_kyc_comparison_details issue'
      ).deliver
      return false
    end

    return false if @user_kyc_comparison_detail.image_processing_status !=
        GlobalConstant::ImageProcessing.processed_image_process_status

    @user_kyc_detail = UserKycDetail.where(client_id: @user_kyc_comparison_detail.client_id,
                                           user_extended_detail_id: @user_kyc_comparison_detail.user_extended_detail_id,
                                           status: GlobalConstant::UserKycDetail.active_status).first
    return false if @user_kyc_detail.blank?

    @client_kyc_pass_setting = ClientKycPassSetting.get_active_setting_from_memcache(@user_kyc_detail.client_id)

    @client_token_sale_detail = ClientTokenSaleDetail.get_from_memcache(@user_kyc_detail.client_id)
    @user_extended_detail = UserExtendedDetail.where(id: @user_extended_detail_id).first

    true
  end


  def compute_auto_approval
    # unset
    GlobalConstant::KycAutoApproveFailedReason.auto_approve_fail_reasons.each do |reason|
      @user_kyc_comparison_detail.send('unset_' + reason)
    end

    if @user_kyc_detail.case_closed_for_auto_approve?
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.case_closed_for_auto_approve)
    end

    if !@client_token_sale_detail.is_token_sale_live?
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.token_sale_ended)
    end

    if @user_extended_detail.residence_proof_file_path.present?
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.residency_proof)
    end

    if @user_extended_detail.investor_proof_files_path.present?
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.investor_proof)
    end

    if UserExtendedDetail.is_duplicate_kyc_approved_user?(@user_kyc_detail.client_id, @user_extended_detail_id)
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc)
    end

    fr_match_percent = @client_kyc_pass_setting.face_match_percent.to_i

    if (@user_kyc_comparison_detail.big_face_match_percent < fr_match_percent) ||
        (@user_kyc_comparison_detail.small_face_match_percent < fr_match_percent)
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.fr_unmatch)
    end


    @client_kyc_pass_setting.ocr_comparison_fields_array.each do |compare_field_name|
      key = "#{compare_field_name}_match_percent"
      if @user_kyc_comparison_detail[key.to_sym] < 100
        @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.ocr_unmatch)
        break
      end
    end

  end

end