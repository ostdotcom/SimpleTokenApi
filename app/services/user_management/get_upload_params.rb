module UserManagement

  class GetUploadParams < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] user_id (mandatory)
    # @param [Hash] images (mandatory)
    #
    # @return [UserManagement::GetUploadParams]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]
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
        key = "i/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}-#{@user_id}")
        @upload_params[k] = get_upload_params_for(content_type, key)
      end

      @pdfs.each do |k, v|
        content_type = v
        key = "d/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}-#{@user_id}")
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

      return error_with_data(
          'um_gup_2',
          'Token Sale Has Ended',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if GlobalConstant::TokenSale.is_general_sale_ended?


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

    # Perform
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
