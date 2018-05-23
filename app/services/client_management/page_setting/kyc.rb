module ClientManagement
  module PageSetting

    class Kyc < Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      #
      # @return [ClientManagement::PageSetting::Kyc]
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        super
      end

      private

      # gives template_data_for_page
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Hash] template data for specific page
      #
      def page_data
        client_kyc_config_detail_obj = ClientKycConfigDetail.get_from_memcache(@client_id)

        kyc_fields = client_kyc_config_detail_obj.kyc_fields_array
        max_investor_proofs_allowed = kyc_fields.include?(GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field) ?
                                      GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed : 0
        extra_data = {
            residency_proof_nationalities: client_kyc_config_detail_obj.residency_proof_nationalities,
            kyc_fields: kyc_fields,
            max_investor_proofs_allowed: max_investor_proofs_allowed
        }

        @client_template_obj.data.merge(extra_data)
      end

      # page template type to fetch info for
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      def page_template_type
        GlobalConstant::ClientTemplate.kyc_template_type
      end

    end
  end
end