module UserManagement

  class BtSubmit < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
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

      @user = nil
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
      update_token_sale_kyc_double_optin_mail_sent
      save_user

      success_with_data(user_id: @user_id)
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

      validation_errors = {}
      @skip_name = ActiveRecord::Type::Boolean.new.cast(@skip_name)
      # apply custom validations. if not skipped
      if !@skip_name
        @bt_name = @bt_name.to_s.strip
        validation_errors[:bt_name] = "Branded Token Name is mandatory." if @bt_name.blank?
        existing_bt_row = User.where(bt_name: @bt_name).first
        validation_errors[:bt_name] = "Branded Token Name is already taken." if existing_bt_row.present? && existing_bt_row.id != @user_id
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
      @user = User.where(id: @user_id).first
    end

    # Update token sale bt done and add name if required
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    def update_token_sale_bt_done
      @user.send("set_"+GlobalConstant::User.token_sale_bt_done_property)
      @user.bt_name = @bt_name unless @skip_name
    end

    # Update token sale kyc double optin mail property and enqueue task
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    def update_token_sale_kyc_double_optin_mail_sent
      if !@user.send(GlobalConstant::User.token_sale_double_optin_mail_sent_property+"?")
        @user.send("set_"+GlobalConstant::User.token_sale_double_optin_mail_sent_property)
        BgJob.enqueue(
          OnBTSubmitJob,
          {
                user_id: @user_id
            }
        )
      end
    end

    # Save user
    #
    # * Author: Kedar
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    def save_user
      @user.save! if @user.changed?
    end

  end

end
