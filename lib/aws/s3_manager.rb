module Aws

  class S3Manager

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] purpose - this is the purpose for accessing the KMS service - login OR kyc
    # @param [String] role - this is the role of the user for whom the KMS service is being called - admin OR user
    #
    # @return [Aws::S3Manager]
    #
    def initialize(purpose, role)
      @purpose = purpose
      @role = role
    end

    # Get signed url for
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] s3_path - this is the S3 key
    #
    # @return [Resul::Base]
    #
    def get_signed_url_for(bucket, s3_path)
      signer = Aws::S3::Presigner.new({client: client})
      signer.presigned_url(
        :get_object,
        bucket: bucket,
        key: s3_path
      )
    end

    private

    # Client
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Aws::KMS::Client]
    #
    def client
      @client ||= Aws::S3::Client.new(
        access_key_id: credentials['access_key'],
        secret_access_key: credentials['secret_key'],
        region: region
      )
    end

    # Access key
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [String] returns access key for AWS
    #
    def access_key_id
      credentials['access_key']
    end

    # Secret key
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [String] returns secret key for AWS
    #
    def secret_key
      credentials['secret_key']
    end

    # Region
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [String] returns region
    #
    def region
      GlobalConstant::Aws::Common.region
    end

    # Credentials
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Hash] returns Hash of AWS credentials
    #
    def credentials
      @credentials ||= GlobalConstant::Aws::Common.get_credentials_for(@role)
    end

  end

end