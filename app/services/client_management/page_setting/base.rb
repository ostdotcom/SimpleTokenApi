module ClientManagement
  module PageSetting
    class Base < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      #
      # @return [ClientManagement::PageSetting::Base]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]

        @client = nil
        @common_client_template_obj = nil
        @client_template_obj = nil
        @client_kyc_config_detail_obj = nil
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
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        fetch_common_template

        fetch_current_page_template

        fetch_kyc_config_detail

        success_with_data(template_info_response)
      end

      private

      # validate
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate
        r = super
        return r unless r.success?

        success
      end

      #  fetch common template info for client
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # Sets @common_client_template_obj
      #
      def fetch_common_template
        @common_client_template_obj = ClientTemplate.get_from_memcache_by_client_id_and_template_type(@client_id, GlobalConstant::ClientTemplate.common_template_type)
      end

      #  fetch page template info for client
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # Sets @client_template_obj
      #
      def fetch_current_page_template
        @client_template_obj = ClientTemplate.get_from_memcache_by_client_id_and_template_type(@client_id, page_template_type)
      end

      # fetch  client kyc config detail obj
      #
      # * Author: Tejas
      # * Date: 30/07/2018
      # * Reviewed By:
      #
      # Sets @client_kyc_config_detail_obj
      #
      def fetch_kyc_config_detail
        @client_kyc_config_detail_obj = ClientKycConfigDetail.get_from_memcache(@client_id)
      end

      # page template type to fetch info for
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      def page_template_type
        fail 'method not implemented page_template_type'
      end

      # gives common_template_data_for_page
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Hash] common template data
      #
      def common_data
        @common_client_template_obj.data
      end

      # gives template_data_for_page
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Hash] template data for specific page
      #
      def page_data
        @client_template_obj.data
      end

      # gives kyc_config_data
      #
      # * Author: Tejas
      # * Date: 30/07/2018
      # * Reviewed By:
      #
      # @return [Hash] template data for specific page
      #
      def kyc_config_data
        kyc_fields = @client_kyc_config_detail_obj.kyc_fields_array
        max_investor_proofs_allowed = kyc_fields.include?(GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field) ?
                                          GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed : 0

        {
            kyc_fields: kyc_fields,
            residency_proof_nationalities: @client_kyc_config_detail_obj.residency_proof_nationalities,
            blacklisted_countries: @client_kyc_config_detail_obj.blacklisted_countries,
            max_investor_proofs_allowed: max_investor_proofs_allowed
        }
      end

      # response data
      #
      # * Author: Aman
      # * Date: 08/02/2018
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def template_info_response
        {
            common_data: common_data,
            page_data: page_data,
            kyc_config_detail_data: kyc_config_data
        }
      end

    end
  end
end