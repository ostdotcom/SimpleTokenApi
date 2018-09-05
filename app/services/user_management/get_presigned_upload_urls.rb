module UserManagement

  class GetPresignedUploadUrls < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # @params [Integer] client_id (mandatory) - logged in admin's client id
    # @param [Hash] images (mandatory)
    # @param [Hash] pdfs (mandatory) - Either pdfs or images should be atleast present
    #
    # @return [UserManagement::GetPresignedUploadUrls]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @images = @params[:images] || {}
      @pdfs = @params[:pdfs] || {}

      @upload_urls = {}
      @client_token_sale_details = nil
    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 04/09/2018
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
        @upload_urls[k] = get_presigned_urls(content_type, key)
      end

      @pdfs.each do |k, v|
        content_type = v
        key = "#{@client_id}/d/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}")
        @upload_urls[k] = get_presigned_urls(content_type, key)
      end

      success_with_data(@upload_urls)

    end

    private

    # Validate
    #
    # * Author: Pankaj
    # * Date: 04/09/2018
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate
      r = super
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      return error_with_data(
          'um_gpuu_1',
          'Invalid parameters',
          'Invalid parameters',
          GlobalConstant::ErrorAction.default,
          {}
      ) if (@pdfs.blank? && @images.blank?) ||
          (@pdfs.present? && !@pdfs.is_a?(Hash) && !@pdfs.is_a?(ActionController::Parameters)) ||
          (@images.present? && !@images.is_a?(Hash) && !@images.is_a?(ActionController::Parameters))

      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)

      #  todo: "KYCaas-Changes"
      return error_with_data(
          'um_gpuu_2',
          'The token sale ended, it is no longer possible to submit personal information.',
          'The token sale ended, it is no longer possible to submit personal information.',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client_token_sale_details.has_token_sale_ended?

      image_content_types = []
      @images.each do |_, v|
        image_content_types << v.to_s.downcase
      end

      pdf_content_types = []
      @pdfs.each do |_, v|
        pdf_content_types << v.to_s.downcase
      end

      invalid_content_types = (image_content_types - ['image/jpeg', 'image/png', 'image/jpg']).any? ||
          (pdf_content_types - ['application/pdf']).any?

      return error_with_data(
          'um_gup_3',
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
    # * Date: 04/09/2018
    # * Reviewed By: Sunil
    #
    # @param [String] content_type
    # @param [String] key
    #
    # @return [Hash]
    #
    def get_presigned_urls(content_type, key)
      Aws::S3Manager.new('kyc', 'user').get_presigned_put_url_for(
          key, GlobalConstant::Aws::Common.kyc_bucket, content_type)
    end

  end

end
