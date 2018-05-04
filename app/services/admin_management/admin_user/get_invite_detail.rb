module AdminManagement

  module AdminUser

    class GetInviteDetail < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @params [String] i_t (mandatory) - token for invite
      #
      # @return [AdminManagement::AdminUser::GetInviteDetail]
      #
      def initialize(params)
        super

        @i_t = @params[:i_t]

        @invite_token = nil
        @temporary_token_id = nil
        @temporary_token_obj = nil
        @admin = nil

      end

      # Perform
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        fetch_temporary_token_obj

        r = validate_invite_token
        return r unless r.success?

        r = fetch_admin
        return r unless r.success?

        success_with_data({name: @admin.name})

      end

      private

      # Validate and sanitize
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # Sets @invite_token, @temporary_token_id
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize

        r = validate
        return incorrect_invite_error('invalid_token') unless r.success?

        decryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
        r = decryptor_obj.decrypt(@i_t)
        return incorrect_invite_error('invalid_token') unless r.success?

        decripted_t = r.data[:plaintext]

        splited_invite_token = decripted_t.split(':')

        return incorrect_invite_error('invalid_token') if splited_invite_token.length != 2

        @invite_token = splited_invite_token[1].to_s

        @temporary_token_id = splited_invite_token[0].to_i

        success
      end

      # Fetch temporary token obj
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # Sets @temporary_token_obj
      #
      def fetch_temporary_token_obj
        @temporary_token_obj = TemporaryToken.where(id: @temporary_token_id).first
      end

      # Validate Token
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_invite_token
        return incorrect_invite_error('invalid_token') if @temporary_token_obj.blank?

        return incorrect_invite_error('invalid_token') if @temporary_token_obj.token != @invite_token

        return incorrect_invite_error('invalid_token') if @temporary_token_obj.kind != GlobalConstant::TemporaryToken.admin_invite_kind

        return incorrect_invite_error('expired_token') if @temporary_token_obj.status != GlobalConstant::TemporaryToken.active_status

        return incorrect_invite_error('expired_token') if @temporary_token_obj.is_expired?

        success
      end

      # Fetch Admin
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # Sets @admin
      #
      # @return [Result::Base]
      #
      def fetch_admin
        @admin = Admin.where(id: @temporary_token_obj.user_id).first
        return incorrect_invite_error('invalid_token') if @admin.blank?
        success
      end

      # Incorrect invite error
      #
      # * Author: Aman
      # * Date: 04/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def incorrect_invite_error(err_code)
        error_with_data(
            err_code,
            'Invalid invite token',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

    end

  end

end
