module UserManagement

  class GetUploadParams < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [Integer] user_id (mandatory)
    # @param [Hash] images (mandatory)
    #
    # @return [UserManagement::GetUploadParams]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]
      @images = @params[:images]

      @aws_creds = nil
      @aws_kms_key_id = nil
      @upload_params = {}
    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def perform

      @aws_creds = GlobalConstant::Aws::Common.get_credentials_for('user')
      @aws_kms_key_id = GlobalConstant::Aws::Kms.get_key_id_for('kyc')

      @images.each do |k, v|
        content_type = v
        key = "i/" + Digest::MD5.hexdigest("#{k}-#{v}-#{Time.now.to_f}-#{rand}-#{@user_id}")
        @upload_params[k] = get_upload_params_for(content_type, key)
      end

      success_with_data(@upload_params)

    end

    private

    # Perform
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] content_type
    # @param [String] key
    #
    # @return [Hash]
    #
    def get_upload_params_for(content_type, key)
      post_policy = {
        key: key,
        content_type: content_type,
        signature_expiration: Time.now + 1800,
        server_side_encryption: 'aws:kms',
        server_side_encryption_aws_kms_key_id: GlobalConstant::Aws::Kms.get_key_id_for('kyc')
      }

      credentials = Aws::Credentials.new(
        @aws_creds['access_key'],
        @aws_creds['secret_key']
      )

      post = Aws::S3::PresignedPost.new(
        credentials,
        GlobalConstant::Aws::Common.region,
        GlobalConstant::Aws::Common.kyc_bucket,
        post_policy
      )

      {url: post.url, fields: post.fields}
    end

  end

end
