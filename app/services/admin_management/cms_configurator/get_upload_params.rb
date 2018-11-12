module AdminManagement

  module CmsConfigurator

    class GetUploadParams < ServicesBase

      CLIENT_ASSET_FILE_PATH_REGEX = /\Ac_assets\/[A-Z0-9\-\/\._]*\z/i

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 10/08/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @param [Hash] images (mandatory)
      #
      # @return [AdminManagement::CmsConfigurator::GetUploadParams]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @images = @params[:images] || {}

        @upload_params = {}
        @client_token_sale_details = nil
      end

      # Perform
      #
      # * Author: Pankaj
      # * Date: 10/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        # File path should always start with client id. There is a validation for it in KycSubmit
        #
        # NOTE: path should contain only [a-z A-Z 0-9 /] character sets
        # CLIENT_ASSET_FILE_PATH_REGEX should be modified if path is changed
        @images.each do |k, v|
          content_type = v
          k_n = k.split("_")[1]
          key = "c_assets/#{Rails.env[0..2]}/#{@client.id}/#{Time.now.to_i}-#{k_n}.#{content_type.split('/')[1]}"
          @upload_params[k] = get_upload_params_for(content_type, key, get_content_length_range(k))
        end

        success_with_data(@upload_params)

      end

      private

      # Validate
      #
      # * Author: Pankaj
      # * Date: 10/08/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate
        r = super
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        return error_with_data(
            'am_cc_gup_1',
            'Invalid parameters',
            'Invalid parameters',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @images.blank? || (!@images.is_a?(Hash) && !@images.is_a?(ActionController::Parameters))

        invalid_content_types = []
        @images.each do |k, v|
          invalid_content_types << k unless file_format_is_valid?(k, v)
        end

        return error_with_data(
            'am_cc_gup_2',
            'Invalid file format',
            'Invalid file format',
            GlobalConstant::ErrorAction.default,
            {}
        ) if invalid_content_types.present?

        success
      end

      # get_upload_params
      #
      # * Author: Pankaj
      # * Date: 10/08/2018
      # * Reviewed By:
      #
      # @param [String] content_type
      # @param [String] key
      #
      # @return [Hash]
      #
      def get_upload_params_for(content_type, key, content_length_range)

        post = Aws::S3Manager.new('login', 'admin').get_presigned_post_url_for_client_assets(content_type, key,
                                                                             GlobalConstant::Aws::Common.client_assets_bucket,
                                                                                             content_length_range)

        {url: post.url, fields: post.fields}
      end

      # get_content_length_range
      #
      # * Author: Pankaj
      # * Date: 20/08/2018
      # * Reviewed By:
      #
      # @param [String] entity_key
      #
      # @return [Range]
      #
      def get_content_length_range(entity_key)
        case entity_key
          when GlobalConstant::CmsConfigurator.company_logo_key
            GlobalConstant::CmsConfigurator.company_logo_file_size_range
          when GlobalConstant::CmsConfigurator.company_favicon_key
            GlobalConstant::CmsConfigurator.company_favicon_file_size_range
          else
            raise "Invalid key"
        end
      end

      def file_format_is_valid?(entity_key, content_type)
        case entity_key
        when GlobalConstant::CmsConfigurator.company_logo_key
          GlobalConstant::CmsConfigurator.company_logo_file_formats.include?(content_type.to_s.downcase)
        when GlobalConstant::CmsConfigurator.company_favicon_key
          GlobalConstant::CmsConfigurator.company_favicon_file_formats.include?(content_type.to_s.downcase)
        else
          raise "Invalid key"
        end
      end

    end

  end

end
