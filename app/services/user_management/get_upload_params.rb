module UserManagement

  class GetUploadParams < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] user_id (mandatory)
    # @params [Integer] client_id (mandatory) - logged in admin's client id
    # @param [Hash] images (mandatory)
    #
    # @return [UserManagement::GetUploadParams]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]
      @client_id = @params[:client_id]
      @images = @params[:images] || {}
      @pdfs = @params[:pdfs] || {}

      @upload_params = {}
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

      @images.each do |k, v|
        content_type = v
        key = "i/#{@client_id}/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}-#{@user_id}")
        @upload_params[k] = get_upload_params_for(content_type, key)
      end

      @pdfs.each do |k, v|
        content_type = v
        key = "d/#{@client_id}/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}-#{@user_id}")
        @upload_params[k] = get_upload_params_for(content_type, key)
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

      #  todo: "KYCaas-Changes"
      return error_with_data(
          'um_gup_3',
          'The token sale ended, it is no longer possible to submit personal information.',
          'The token sale ended, it is no longer possible to submit personal information.',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client.is_st_token_sale_client?

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
          'um_gup_1',
          'invalid content types.',
          'Only JPEG, PDF and PNG files are allowed.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if invalid_content_types

      success
    end

    # fetch client and validate
    #
    # * Author: Aman
    # * Date: 26/12/2017
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def fetch_and_validate_client
      @client = Client.get_from_memcache(@client_id)

      return error_with_data(
          'um_gup_2',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client.status != GlobalConstant::Client.active_status

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
    def get_upload_params_for(content_type, key)

      post = Aws::S3Manager.new('kyc', 'user').get_presigned_post_url_for(content_type, key, GlobalConstant::Aws::Common.kyc_bucket)

      {url: post.url, fields: post.fields}
    end

  end

end
