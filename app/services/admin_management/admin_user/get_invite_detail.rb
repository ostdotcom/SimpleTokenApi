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

        @api_response_data = {}
        @invalid_token = false

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

        set_api_response_data

        success_with_data(@api_response_data)

      end

      private

      # Validate and sanitize
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # Sets @invite_token, @temporary_token_id, @invalid_token
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize

        # dont return error but set @invalid_token as true
        r = validate
        unless r.success?
          @invalid_token = true
          return success
        end

        decryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
        r = decryptor_obj.decrypt(@i_t)
        unless r.success?
          @invalid_token = true
          return success
        end

        decripted_t = r.data[:plaintext]

        splited_invite_token = decripted_t.split(':')

        if splited_invite_token.length != 2
          @invalid_token = true
          return success
        end

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
        return if @invalid_token
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

        return success if @invalid_token

        if @temporary_token_obj.blank? || @temporary_token_obj.token != @invite_token ||
            @temporary_token_obj.kind != GlobalConstant::TemporaryToken.admin_invite_kind
          @invalid_token = true
          return success
        end

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
        return success if @invalid_token

        @admin = Admin.where(id: @temporary_token_obj.user_id).first

        @invalid_token = true if @admin.blank?

        success
      end

      # set response data
      #
      # * Author: Aman
      # * Date: 03/05/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      def set_api_response_data

        @api_response_data = {
            invalid_token: @invalid_token.to_i
        }

        if !@invalid_token

          if @temporary_token_obj.status != GlobalConstant::TemporaryToken.active_status || @temporary_token_obj.is_expired?
            @api_response_data[:is_expired] = true.to_i
          end

          @api_response_data[:admin] = {
              name: @admin.name
          }
        end

      end

    end

  end

end
