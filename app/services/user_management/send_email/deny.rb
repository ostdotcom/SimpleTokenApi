module UserManagement
  module SendEmail

    class Deny < Base
      # Initialize
      #
      # * Author: Mayur
      # * Date: 14/12/2018
      # * Reviewed By:
      #
      # @param [AR] client (mandatory) - client obj
      # @param [Integer] user_id (mandatory) - user id
      # @param [Hash] template_vars (optional) - @template_vars
      #
      # @return [UserManagement::SendEmail::Deny]
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Mayur
      # * Date: 14/12/2018
      # * Reviewed By:
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        r = fetch_and_validate_user_kyc_detail
        return r unless r.success?

        create_email_hook(GlobalConstant::PepoCampaigns.kyc_denied_template)

        success
      end

      private

      # Fetch and validate user kyc details
      #
      # * Author: Mayur
      # * Date: 14/12/2018
      # * Reviewed By:
      #
      def fetch_and_validate_user_kyc_detail
        user_kyc_detail = UserKycDetail.using_client_shard(client: @client).get_from_memcache(@user_id)

        return error_with_identifier('kyc_not_denied',
                                     'um_se_d_favukd_1'
        ) if (user_kyc_detail.blank? || (user_kyc_detail.client_id != @client_id)) || !(user_kyc_detail.kyc_denied?)

        success
      end



    end

  end
end
