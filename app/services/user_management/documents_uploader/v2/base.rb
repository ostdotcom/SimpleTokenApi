module UserManagement
  module DocumentsUploader
    module V2
      class Base < ServicesBase

        #NOTE: Update value in param_errors for key: 'invalid_files_count'
        MAX_ALLOWED_KEYS = 20

        # Initialize
        #
        # * Author: Kedar
        # * Date: 13/10/2017
        # * Reviewed By:
        #
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @param [Hash] files (mandatory)
        #
        #
        def initialize(params)
          super

          @client_id = @params[:client_id]

          @files = @params[:files] || {}
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

          @files.each do |k, v|
            content_type = v
            directory = ''

            if ['image/jpeg', 'image/png', 'image/jpg'].include?(content_type)
              directory = 'i'
            elsif 'application/pdf' == content_type
              directory = 'd'
            end

            key = "#{@client_id}/#{directory}/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}")
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
              ['missing_files']
          ) if @files.blank?

          params_error_identifiers = []

          params_error_identifiers << 'invalid_files' if @files.present? && !Util::CommonValidateAndSanitize.is_hash?(@files)

          return error_with_identifier(
              'invalid_api_params',
              'um_gup_v_2',
              params_error_identifiers
          ) if params_error_identifiers.present?

          return error_with_identifier('invalid_api_params',
                                       'um_gup_v_3',
                                       ['invalid_files_count']
          )if @files.length > MAX_ALLOWED_KEYS

          @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)

          return error_with_identifier(
              'token_sale_ended',
              'um_gup_v_4'
          ) if @client_token_sale_details.has_token_sale_ended?

          file_content_types = []
          @files.each do |_, v|
            file_content_types << v.to_s.downcase
          end
          params_error_identifiers << 'invalid_files' if (file_content_types - ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf']).any?

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
