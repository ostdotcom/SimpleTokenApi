module UserManagement

  class BtSubmit < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @param [Integer] user_id (mandatory) - user id
    # @param [String] bt_name (mandatory) - Branded Token Name
    # @param [Boolean] skip_name (mandatory) - skip this step
    #
    # @return [UserManagement::BtSubmit]
    #
    def initialize(params)

      super

      @user_id = @params[:user_id]
      @bt_name = @params[:bt_name]
      @skip_name = @params[:skip_name]
      @client_id = @params[:client_id]

      @user = nil

      #  todo: "KYCaas-Changes"
      # @enqueue_task = false

    end

    # Perform
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      fetch_user

      update_token_sale_bt_done

      #  todo: "KYCaas-Changes"
      # update_token_sale_kyc_double_optin_mail_sent

      save_user

      #  todo: "KYCaas-Changes"
      # enqueue_job if @enqueue_task

      success

    end

    private

    # Validate and sanitize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      return error_with_data(
          'um_bs_1',
          'Invalid action',
          'Invalid action',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client_id != GlobalConstant::TokenSale.st_token_sale_client_id


      validation_errors = {}
      @skip_name = ActiveRecord::Type::Boolean.new.cast(@skip_name)
      # apply custom validations. if not skipped
      if !@skip_name
        @bt_name = @bt_name.to_s.strip

        if @bt_name.blank?
          validation_errors[:bt_name] = "Branded Token Name is mandatory."

        else
          if !Util::CommonValidateAndSanitize.is_alphanumeric?(@bt_name)
            validation_errors[:bt_name] = "Only A-Z and 0-9 characters are allowed. No spaces allowed"
          else
            if @bt_name.downcase == 'simpletoken'
              validation_errors[:bt_name] = "Branded Token Name is already taken."
            else
              existing_bt_row = User.where(client_id: @client_id, bt_name: @bt_name).first
              if existing_bt_row.present? && existing_bt_row.id != @user_id
                validation_errors[:bt_name] = "Branded Token Name is already taken."
              else
                user_kyc_detail = UserKycDetail.where(client_id: @client_id, user_id: @user_id).first
                if user_kyc_detail.present? && user_kyc_detail.kyc_denied?
                  validation_errors[:bt_name] = "Your KYC is denied. Token Name cannot be reserved"
                end
              end

            end
          end
        end
      end

      return error_with_data(
          'um_bs_1',
          'Branded Token name error.',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          validation_errors
      ) if validation_errors.present?

      success
    end

    # fetch user
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user
    #
    def fetch_user
      @user = User.get_from_memcache(@user_id)
    end

    # Update token sale bt done and add name if required
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    def update_token_sale_bt_done
      #  todo: "KYCaas-Changes"
      # @user.send("set_"+GlobalConstant::User.token_sale_bt_done_property)
      @user.bt_name = @bt_name unless @skip_name
    end

    # Update token sale kyc double optin mail property and enqueue task
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    #  todo: "KYCaas-Changes"
    # def update_token_sale_kyc_double_optin_mail_sent
    #   if !@user.send(GlobalConstant::User.token_sale_double_optin_mail_sent_property+"?")
    #     @enqueue_task = true
    #     #TODO: Handle multiple concurrent requests for same bt update
    #     @user.send("set_"+GlobalConstant::User.token_sale_double_optin_mail_sent_property)
    #   end
    # end

    # Save User
    #
    # * Author: Aman
    # * Date: 15/10/2017
    # * Reviewed By: Sunil
    #
    def save_user
      @user.save! if @user.changed?
    end

    # Enqueue task
    #
    # * Author: Aman
    # * Date: 15/10/2017
    # * Reviewed By: Sunil
    #
    #  todo: "KYCaas-Changes"
    # def enqueue_job
    #   BgJob.enqueue(
    #       SendDoubleOptIn,
    #       {
    #           user_id: @user_id
    #       }
    #   )
    # end

  end

end
