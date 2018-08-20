module AdminManagement

  module CmsConfigurator

    class GetUploadParams < ServicesBase

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
        # NOTE:: path should contain only [a-z A-Z 0-9 /] character sets
        @images.each do |k, v|
          content_type = v
          key = "c_assets/#{@client.id}/#{Time.now.to_i}-logo.#{content_type.split('/')[1]}"
          @upload_params[k] = get_upload_params_for(content_type, key)
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

        image_content_types = []
        @images.each do |_, v|
          image_content_types << v.to_s.downcase
        end

        invalid_content_types = (image_content_types - ['image/jpeg', 'image/png', 'image/jpg', 'image/ico']).any?

        return error_with_data(
            'am_cc_gup_2',
            'invalid content types.',
            'Only JPEG, PDF and PNG files are allowed.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if invalid_content_types

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
      def get_upload_params_for(content_type, key)

        post = Aws::S3Manager.new('login', 'admin').get_presigned_post_url_for_client_assets(content_type, key,
                                                                             GlobalConstant::Aws::Common.client_assets_bucket)

        {url: post.url, fields: post.fields}
      end

    end

  end

end
