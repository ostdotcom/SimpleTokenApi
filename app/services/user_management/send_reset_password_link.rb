module UserManagement

  class SendResetPasswordLink < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @params [String] email (mandatory) - this is the email entered
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
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      r = fetch_user
      return r unless r.success?

      r = create_reset_password_token
      return r  unless r.success?

      send_forgot_password_mail

      success
    end

    private

    # Fetch user
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
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
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {email: 'This user is not registered or is blocked'}
      ) unless @user.present? && @user.password.present? && (@user.status == GlobalConstant::User.active_status)

      success
    end

    # Create Double Opt In Token
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @reset_password_token
    #
    # @return [Result::Base]
    #
    def create_reset_password_token
      reset_token = Digest::MD5.hexdigest("#{@user.id}::#{@user.password}::#{Time.now.to_i}::reset_password::#{rand}")
      db_row = TemporaryToken.create!(user_id: @user.id, kind: GlobalConstant::TemporaryToken.reset_password_kind, token: reset_token)

      reset_pass_token_str = "#{db_row.id.to_s}:#{reset_token}"
      encryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
      r = encryptor_obj.encrypt(reset_pass_token_str)
      return r unless r.success?

      @reset_password_token = r.data[:ciphertext_blob]

      success
    end

    # Send forgot password_mail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    def send_forgot_password_mail
      Email::HookCreator::SendTransactionalMail.new(
          client_id: GlobalConstant::TokenSale.st_token_sale_client_id,
          email: @user.email,
          template_name: GlobalConstant::PepoCampaigns.forgot_password_template,
          template_vars: {
              reset_password_token: @reset_password_token
          }
      ).perform
    end

  end
end
