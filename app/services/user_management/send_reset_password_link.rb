module UserManagement

  class SendResetPasswordLink < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @param [String] email (mandatory) - this is the email entered
    #
    # @return [UserManagement::SendResetPasswordLink]
    #
    def initialize(params)
      super

      @email = @params[:email]

      @user = nil
      @reset_password_token = nil

    end

    # Perform
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      r = fetch_user
      return r unless r.success?

      invalidate_active_reset_password_tokens

      create_reset_password_token

      send__forgot_password_mail

      success
    end

    private

    # Fetch user
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def fetch_user
      @user = User.where(email: @email).first

      return error_with_data(
          'um_srpl_1',
          'User not present',
          'Email is not registered',
          GlobalConstant::ErrorAction.default,
          {},
          {email: "This user is not registered"}
      ) unless @user.present?

      success
    end

    # Mark active reset password tokens to inactive
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    def invalidate_active_reset_password_tokens
      TemporaryToken.where(user_id: @user_id, kind: GlobalConstant::TemporaryToken.reset_password_kind, status: GlobalConstant::TemporaryToken.active_status).update_all(status: GlobalConstant::TemporaryToken.inactive_status)
    end

    # Create Double Opt In Token
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # Sets @reset_password_token
    #
    def create_reset_password_token
      reset_token = Digest::MD5.hexdigest("#{@user.id}::#{@user.password}::#{Time.now.to_i}::reset_password::#{rand}")
      db_row = TemporaryToken.create!(user_id: @user_id, kind: GlobalConstant::TemporaryToken.reset_password_kind, token: reset_token)
      @reset_password_token = "#{db_row.id.to_s}:#{reset_token}"
    end

    # Send forgot password_mail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    def send__forgot_password_mail
      Email::HookCreator::SendTransactionalMail.new(
          email: @user.email,
          template_name: GlobalConstant::PepoCampaigns.forgot_password_template,
          template_vars: {
              reset_password_token: @reset_password_token
          }
      ).perform
    end

  end
end
