module UserAction

  class ChangePhase

    # Initialize
    #
    # * Author: Abhay
    # * Date: 15/11/2017
    # * Reviewed By: Sunil
    #
    # @param [Array] emails (mandatory)
    #
    # Sets @emails
    #
    def initialize(params)
      @emails = params[:emails]
      ActiveRecord::Base.logger = Logger.new(STDOUT)
    end

    # Perform
    #
    # * Author: Abhay
    # * Date: 15/11/2017
    # * Reviewed By: Sunil
    #
    def perform
      admin_email = 'francesco@simpletoken.org'

      p "total users phase to change: #{@emails.count}"

      @emails.each do |email|

        p "Changing phase for email: #{email}"

        user = User.where(email: email).first
        if user.blank?
          p 'User not found'
          next
        end

        user_kyc_detail = UserKycDetail.where(user_id: user.id).first
        if user_kyc_detail.blank?
          p 'User KYC not found'
          next
        end

        admin = Admin.where(email: admin_email).first

        if user_kyc_detail.token_sale_participation_phase != GlobalConstant::TokenSale.general_access_token_sale_phase
          p "Phase mismatch value"
          next
        end
        user_kyc_detail.token_sale_participation_phase = GlobalConstant::TokenSale.early_access_token_sale_phase
        user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status
        user_kyc_detail.record_timestamps = false
        user_kyc_detail.save!

        UserActivityLogJob.new().perform({
                                           user_id: user_kyc_detail.user_id,
                                           admin_id: admin.id,
                                           action: GlobalConstant::UserActivityLog.phase_changed_to_early_access,
                                           action_timestamp: Time.now.to_i,
                                           extra_data: {
                                             phase: GlobalConstant::TokenSale.early_access_token_sale_phase
                                           }
                                         })

        Email::HookCreator::AddContact.new(
          email: user.email,
          custom_attributes: {
            GlobalConstant::PepoCampaigns.token_sale_phase_attribute => user_kyc_detail.token_sale_participation_phase
          }
        ).perform

      end

    end

  end

end