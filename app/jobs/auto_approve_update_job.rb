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
  # @param [Integer] client_id - client id
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
          client: @client,
          is_auto_approve: true
      }

      service_response = AdminManagement::Kyc::AdminAction::ApproveDetails.new(qualify_params).perform

      ApplicationMailer.notify(
          body: 'Unable to Auto Approve a valid case',
          data: {
              user_extended_detail_id: @user_extended_detail_id,
              user_kyc_comparison_detail_id: @user_kyc_comparison_detail.id
          },
          subject: 'Unable to Auto Approve a valid case'
      ).deliver if !service_response.success?

    else
      send_manual_review_needed_email
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
  def init_params(params)
    @client_id = params[:client_id]
    @user_extended_detail_id = params[:user_extended_details_id]
    @reprocess = params[:reprocess].to_i
  end

  # Fetch required models
  #
  # * Author: Aniket
  # * Date: 11/07/2018
  # * Reviewed By:
  #
  # Sets @client, @user_kyc_comparison_detail, @user_kyc_detail,
  #     @client_token_sale_detail, @client_kyc_pass_setting, @user_extended_detail
  #
  def fetch_and_validate_models
    @client = Client.get_from_memcache(@client_id)

    @user_kyc_comparison_detail = UserKycComparisonDetail.using_client_shard(client: @client).
        where(user_extended_detail_id: @user_extended_detail_id).first

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

    @user_kyc_detail = UserKycDetail.using_client_shard(client: @client).
        where(client_id: @user_kyc_comparison_detail.client_id,
              user_extended_detail_id: @user_kyc_comparison_detail.user_extended_detail_id,
              status: GlobalConstant::UserKycDetail.active_status).first

    return false if @user_kyc_detail.blank? || @user_kyc_detail.has_been_auto_approved?

    @client_kyc_pass_setting = ClientKycPassSetting.get_active_setting_from_memcache(@user_kyc_detail.client_id)

    @client_token_sale_detail = ClientTokenSaleDetail.get_from_memcache(@user_kyc_detail.client_id)
    @user_extended_detail = UserExtendedDetail.using_client_shard(client: @client).where(id: @user_extended_detail_id).first

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

    if @client_token_sale_detail.has_token_sale_ended?
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.token_sale_ended)
    end

    if @user_extended_detail.residence_proof_file_path.present?
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.residency_proof)
    end

    if @user_extended_detail.investor_proof_files_path.present?
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.investor_proof)
    end

    if UserExtendedDetail.using_client_shard(client: @client).
        is_duplicate_kyc_approved_user?(@user_kyc_detail.client_id, @user_extended_detail_id)
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc)
    end

    fr_match_percent = @client_kyc_pass_setting.face_match_percent.to_i

    if (@user_kyc_comparison_detail.big_face_match_percent < fr_match_percent) ||
        (@user_kyc_comparison_detail.small_face_match_percent < fr_match_percent)
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.fr_unmatch)
    end

    if @user_kyc_comparison_detail.selfie_human_labels_percent < 90
      @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.human_labels_percentage_low)
    end

    @client_kyc_pass_setting.ocr_comparison_fields_array.each do |compare_field_name|
      key = "#{compare_field_name}_match_percent"
      if @user_kyc_comparison_detail[key.to_sym] < 100
        @user_kyc_comparison_detail.send('set_' + GlobalConstant::KycAutoApproveFailedReason.ocr_unmatch)
        break
      end
    end

  end

  # Send Manual review needed email to admins
  #
  # * Author: Aman
  # * Date: 24/01/2019
  # * Reviewed By:
  #
  #
  def send_manual_review_needed_email
    return if (@reprocess == 1) || !@user_kyc_detail.send_manual_review_needed_email?

    review_type =  (@client_kyc_pass_setting.approve_type == GlobalConstant::ClientKycPassSetting.auto_approve_type) &&
        (@user_kyc_comparison_detail.auto_approve_failed_reasons_array &
        GlobalConstant::KycAutoApproveFailedReason.ocr_fr_review_type_failed_reasons).present? ?
                      GlobalConstant::PepoCampaigns.ocr_fr_failed_review_type :
                      GlobalConstant::PepoCampaigns.manual_review_type

    template_variables = {
        case_id: @user_kyc_detail.id,
        full_name: @user_extended_detail.get_full_name,
        review_type: review_type
    }

    admin_emails = GlobalConstant::Admin.get_all_admin_emails_for(
        @user_kyc_comparison_detail.client_id,
        GlobalConstant::Admin.manual_review_needed_notification_type
    )

    admin_emails.each do |admin_email|
      ::Email::HookCreator::SendTransactionalMail.new(
          client_id: ::Client::OST_KYC_CLIENT_IDENTIFIER,
          email: admin_email,
          template_name: ::GlobalConstant::PepoCampaigns.manual_review_needed_template,
          template_vars: template_variables
      ).perform

    end

  end

end