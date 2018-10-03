module UserManagement
  module DocumentsUploader
    module V2
      class Base < ServicesBase

        #NOTE: Update value in param_errors for key: 'invalid_file_count'
        MAX_ALLOWED_KEYS = 20

        # Initialize
        #
        # * Author: Kedar
        # * Date: 13/10/2017
        # * Reviewed By:
        #
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @param [Hash] file (mandatory)
        #
        #
        def initialize(params)
          super

          @client_id = @params[:client_id]

          @file = @params[:file] || {}
          @upload_params = {}
          @client_token_sale_details = nil
        end

        # Perform
        #
        # * Author: Kedar
        # * Date: 13/10/2017
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def perform

          r = validate
          return r unless r.success?

          @file.each do |k, v|
            content_type = v
            key = "#{@client_id}/i/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}")
            @upload_params[k] = get_url(content_type, key)
          end

          success_with_data(@upload_params)

        end

        private

        # Validate
        #
        # * Author: Kedar
        # * Date: 13/10/2017
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def validate
          r = super
          return r unless r.success?

          r = fetch_and_validate_client
          return r unless r.success?

          return error_with_identifier(
              'invalid_api_params',
              'um_gup_v_1',
              ['missing_file']
          ) if @file.blank?

          params_error_identifiers = []

          params_error_identifiers << 'invalid_file' if @file.present? && !Util::CommonValidateAndSanitize.is_hash?(@file)

          return error_with_identifier(
              'invalid_api_params',
              'um_gup_v_2',
              params_error_identifiers
          ) if params_error_identifiers.present?

          return error_with_identifier('invalid_api_params',
                                       'um_gup_v_3',
                                       ['invalid_file_count']
          )if @file.length > MAX_ALLOWED_KEYS

          @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)

          return error_with_identifier(
              'token_sale_ended',
              'um_gup_v_4'
          ) if @client_token_sale_details.has_token_sale_ended?

          file_content_types = []
          @file.each do |_, v|
            file_content_types << v.to_s.downcase
          end
          params_error_identifiers << 'invalid_file' if (file_content_types - ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf']).any?

          return error_with_identifier(
              'invalid_api_params',
              'um_gup_v_5',
              params_error_identifiers
          ) if params_error_identifiers.present?

          success
        end

        # # Get AWS Url
        #
        # * Author: Kedar
        # * Date: 13/10/2017
        # * Reviewed By:
        #
        # @param [String] content_type
        # @param [String] key
        #
        # @return [Hash]
        #
        def get_url(content_type, key)
          fail 'Subclass would implement'
        end

      end
    end
  end
end
