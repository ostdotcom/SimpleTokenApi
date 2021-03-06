module UserManagement

  class SendResetPasswordLink < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [AR] client (mandatory) - client obj
    # @params [String] email (mandatory) - this is the email entered
    #
    # @return [UserManagement::SendResetPasswordLink]
    #
    def initialize(params)
      super

      @email = @params[:email]
      @client = @params[:client]

      @client_id = @client.id
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

      r = validate_client_details
      return r unless r.success?

      # do not send error if user is not present.
      # The response should be generic even if user is not present.
      # Security audit-ST-03-002 Web: User Enumeration via Password Forget (Info)

      r = fetch_user

      if r.success?
        r = create_reset_password_token
        return r unless r.success?

        send_forgot_password_mail
      end

      success
    end

    private

    # validate clients web hosting setup details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_client_details

      return error_with_data(
          'um_srpl_1',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_web_host_setup_done?

      success
    end

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
      @user = User.using_client_shard(client: @client).where(client_id: @client_id, email: @email).first

      return error_with_data(
          'um_srpl_2',
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
      db_row = TemporaryToken.create!({
                                          client_id: @client_id,
                                          entity_id: @user.id,
                                          kind: GlobalConstant::TemporaryToken.reset_password_kind,
                                          token: reset_token
                                      })

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
          client_id: @client_id,
          email: @user.email,
          template_name: GlobalConstant::PepoCampaigns.user_forgot_password_template,
          template_vars: {
              reset_password_token: @reset_password_token
          }
      ).perform
    end

  end
end
