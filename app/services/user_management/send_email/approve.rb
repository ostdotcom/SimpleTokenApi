module UserManagement
  module SendEmail

    class Approve < ServicesBase
      # Initialize
      #
      # * Author: Mayur
      # * Date: 03/12/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      # @param [Integer] user_id (mandatory) - user id
      # @param [Hash] template_vars (optional) - @template_vars
      #
      # @return [UserManagement::SendEmail::Approve]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @user_id = @params[:user_id]
        @template_vars = @params[:template_vars] || {}

        @client = nil
        @user = nil
      end

      # Perform
      #
      # * Author: Mayur
      # * Date: 03/12/2018
      # * Reviewed By:
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        create_email_hook

        success
      end

      private

      # Validate and sanitize
      #
      # * Author: Mayur
      # * Date: 03/12/2018
      # * Reviewed By:
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        r = validate_and_sanitize_params
        return r unless r.success?

        r = fetch_and_validate_user
        return r unless r.success?

        r = fetch_and_validate_user_kyc_detail
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        success
      end

      # Validate and sanitize params
      #
      # * Author: Mayur
      # * Date: 03/12/2018
      # * Reviewed By:
      #
      def validate_and_sanitize_params
        error_indentifiers = []
        error_indentifiers << 'invalid_user_id' unless Util::CommonValidateAndSanitize.is_integer?(@user_id)
        error_indentifiers << 'invalid_template_vars' unless is_valid_template_vars?

        return error_with_identifier('invalid_api_params',
                                     'um_se_a_vasp_1',
                                     error_indentifiers
        ) if error_indentifiers.any?
        @user_id = @user_id.to_i

        success
      end


      # Fetch and validate user
      #
      # * Author: Mayur
      # * Date: 05/12/2018
      # * Reviewed By:
      #
      def fetch_and_validate_user
        @user = User.get_from_memcache(@user_id)

        return error_with_identifier('resource_not_found',
                                     'um_se_a_favu_1'
        ) if (@user.blank?) || (@user.client_id != @client_id) || (@user.status != GlobalConstant::User.active_status)

        success
      end

      # Fetch and validate user kyc details
      #
      # * Author: Mayur
      # * Date: 05/12/2018
      # * Reviewed By:
      #
      def fetch_and_validate_user_kyc_detail
        user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)

        return error_with_identifier('kyc_not_approved',
                                     'um_se_a_favukd_1'
        ) if (user_kyc_detail.blank? || (user_kyc_detail.client_id != @client_id)) || !(user_kyc_detail.kyc_approved?)

        success
      end


      # Create email hook
      #
      # * Author: Mayur
      # * Date: 05/12/2018
      # * Reviewed By:
      #
      def create_email_hook
        @template_vars = @template_vars.as_json.deep_symbolize_keys.
            reverse_merge(GlobalConstant::PepoCampaigns.kyc_approve_default_template_vars(@client_id))

        Email::HookCreator::SendTransactionalMail.new(
            client_id: @client_id,
            email: @user.email,
            template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
            template_vars: @template_vars
        ).perform
      end


      # Check if template_vars is valid. nested objects or arrays are not allowed
      #
      # * Author: Mayur
      # * Date: 03/12/2018
      # * Reviewed By:
      #
      def is_valid_template_vars?

        return false unless Util::CommonValidateAndSanitize.is_hash?(@template_vars)

        @template_vars.each do |_, val|
          if Util::CommonValidateAndSanitize.is_hash?(val)
            val.each do |_, v|
              return false if check_if_hash_or_array(v)
            end
          elsif Util::CommonValidateAndSanitize.is_array?(val)
            val.each do |v|
              return false if check_if_hash_or_array(v)
            end
          end
        end

        true
      end

      # Check if array or hash type
      #
      # * Author: Mayur
      # * Date: 03/12/2018
      # * Reviewed By:
      #
      def check_if_hash_or_array(v)
        Util::CommonValidateAndSanitize.is_hash?(v) || Util::CommonValidateAndSanitize.is_array?(v)
      end


    end

  end
end
