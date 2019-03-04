module UserManagement

  module DocumentsUploader

    class Base < ServicesBase

      # Initialize
      #
      # * Author: Kedar
      # * Date: 13/10/2017
      # * Reviewed By: Sunil
      #
      # @param [AR] client (mandatory) - client obj
      # @param [Hash] images (mandatory)
      #
      #
      def initialize(params)
        super

        @client = @params[:client]
        @images = @params[:images] || {}
        @pdfs = @params[:pdfs] || {}

        @client_id = @client.id
        @upload_params = {}
        @client_token_sale_details = nil
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 13/10/2017
      # * Reviewed By: Sunil
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
          key = "#{@client_id}/i/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}")
          @upload_params[k] = get_url(content_type, key)
        end

        @pdfs.each do |k, v|
          content_type = v
          key = "#{@client_id}/d/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}")
          @upload_params[k] = get_url(content_type, key)
        end

        success_with_data(@upload_params)

      end

      private

      # Validate
      #
      # * Author: Kedar
      # * Date: 13/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def validate
        r = super
        return r unless r.success?


        return error_with_identifier(
            'invalid_api_params',
            'um_gup_v_1',
            ['missing_images', 'missing_pdfs']
        ) if (@pdfs.blank? && @images.blank?)

        params_error_identifiers = []

        params_error_identifiers << 'invalid_pdfs' if @pdfs.present? && !Util::CommonValidateAndSanitize.is_hash?(@pdfs)
        params_error_identifiers << 'invalid_images' if @images.present? && !Util::CommonValidateAndSanitize.is_hash?(@images)

        return error_with_identifier(
            'invalid_api_params',
            'um_gup_v_2',
            params_error_identifiers
        ) if params_error_identifiers.present?

        @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)


        return error_with_identifier(
            'token_sale_ended',
            'um_gup_v_3'
        )if @client_token_sale_details.has_token_sale_ended?

        image_content_types = []
        @images.each do |_, v|
          image_content_types << v.to_s.downcase
        end

        pdf_content_types = []
        @pdfs.each do |_, v|
          pdf_content_types << v.to_s.downcase
        end

        params_error_identifiers << 'invalid_pdfs' if  (pdf_content_types - ['application/pdf']).any?
        params_error_identifiers << 'invalid_images' if  (image_content_types - ['image/jpeg', 'image/png', 'image/jpg']).any?

        return error_with_identifier(
            'invalid_api_params',
            'um_gup_v_4',
            params_error_identifiers
        ) if params_error_identifiers.present?

        success
      end

      # # Get AWS Url
      #
      # * Author: Kedar
      # * Date: 13/10/2017
      # * Reviewed By: Sunil
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
