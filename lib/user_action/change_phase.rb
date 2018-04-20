module UserAction

  class ChangePhase

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Abhay
    # * Date: 17/11/2017
    # * Reviewed By: Sunil
    #
    # @param [Array] emails (mandatory)
    # @param [Integer] client_id (mandatory)
    # @param [String] phase (mandatory) early_access/general_access
    # @param [String] Admin Email (mandatory)
    #
    # Sets @emails, @admin_email
    #
    #
    # UserAction::ChangePhase.new(client_id: 1, emails: ['aman+11@pepo.com', 'aman+00@pepo.com'], phase: 'early_access', admin_email: 'abhay@pepo.com').perform
    #
    def initialize(params)
      @client_id = params[:client_id]
      @emails = params[:emails]
      @phase = params[:phase]
      @admin_email = params[:admin_email]
      ActiveRecord::Base.logger = Logger.new(STDOUT)
    end

    # Perform
    #
    # * Author: Abhay
    # * Date: 17/11/2017
    # * Reviewed By: Sunil
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      update_phase
    end

    # Validate and Sanitize
    #
    # * Author: Abhay
    # * Date: 17/11/2017
    # * Reviewed By: Sunil
    #
    # Sets @admin
    #
    def validate_and_sanitize

      @admin_email = @admin_email.to_s.downcase.strip
      @phase = @phase.to_s.downcase.strip

      if @emails.blank? || @admin_email.blank?
        return error_with_data(
            'ua_cp_1',
            'Emails, Admin Email is mandatory!',
            'Emails, Admin Email is mandatory!',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @admin = Admin.where(email: @admin_email, status: GlobalConstant::Admin.active_status).first

      if @admin.blank?
        return error_with_data(
            'ua_cp_3',
            "Invalid Active Admin Email - #{@admin_email}",
            "Invalid Active Admin Email - #{@admin_email}",
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @client = Client.get_from_memcache(@client_id)

      return error_with_data(
          'ua_cp_2',
          'Invalid Active Admin Email or client',
          'Invalid Active Admin Email or client',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client.status != GlobalConstant::Client.active_status

      if [GlobalConstant::TokenSale.early_access_token_sale_phase].exclude?(@phase)
        return error_with_data(
            'ua_cp_4',
            "Invalid phase value: #{@phase}. Script right now supports only general to early access.",
            "Invalid phase value: #{@phase}. Script right now supports only general to early access.",
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      success
    end

    # Update given users phase
    #
    # * Author: Abhay
    # * Date: 15/11/2017
    # * Reviewed By: Sunil
    #
    def update_phase

      p "total users phase to change: #{@emails.count}"
      @emails.each do |email|
        email = email.to_s.downcase.strip
        p "Changing phase for email: #{email}"
        user = User.where(client_id: @client_id, email: email).first
        if user.blank?
          p "email: #{email} not found"
          next
        end

        user_kyc_detail = UserKycDetail.where(user_id: user.id).first
        if user_kyc_detail.blank?
          p "User KYC ID: #{user_kyc_detail.id} not found for email: #{email}"
          next
        end

        if user_kyc_detail.token_sale_participation_phase == @phase
          p "user_kyc_detail phase is already: #{user_kyc_detail.token_sale_participation_phase} "
          next
        end
        user_kyc_detail.token_sale_participation_phase = @phase
        user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status
        user_kyc_detail.record_timestamps = false
        user_kyc_detail.save!

        UserActivityLogJob.new().perform({
                                             user_id: user_kyc_detail.user_id,
                                             admin_id: @admin.id,
                                             action: GlobalConstant::UserActivityLog.phase_changed_to_early_access,
                                             action_timestamp: Time.now.to_i,
                                             extra_data: {
                                                 phase: GlobalConstant::TokenSale.early_access_token_sale_phase
                                             }
                                         })

        r = Email::HookCreator::AddContact.new(
            client_id: @client.id,
            email: user.email,
            custom_attributes: {
                GlobalConstant::PepoCampaigns.token_sale_phase_attribute => user_kyc_detail.token_sale_participation_phase
            }
        ).perform if @client.is_st_token_sale_client?

        if !r.success?
          p "Update Contact failure for email: #{email}"
        end

      end

      success

    end

  end

end