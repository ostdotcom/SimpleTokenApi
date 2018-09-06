module UserManagement

  module DocumentsUploader

    class Base < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @params [Integer] client_id (mandatory) - logged in admin's client id
    # @param [Hash] images (mandatory)
    #
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @images = @params[:images] || {}
      @pdfs = @params[:pdfs] || {}

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

      r = fetch_and_validate_client
      return r unless r.success?

      return error_with_data(
          'um_gup_1',
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
          'um_gup_2',
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
