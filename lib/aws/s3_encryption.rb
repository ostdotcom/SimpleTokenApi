module Aws

  class S3Encryption

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Aman
    # * Date: 09/10/2017
    # * Reviewed By:
    #
    # @param [String] encryption_key - this is the 256 bit symmetric key for encrytion
    # @param [String] role - this is the role of the user for whom the S3 service is being called
    #
    # @return [Aws::S3Encryption]
    #
    def initialize(encryption_key, role)
      @encryption_key = encryption_key
      @role = role
    end

    # Put object
    #
    # * Author: Aman
    # * Date: 09/10/2017
    # * Reviewed By:
    #
    # @param [String] key - this is the s3 location
    # @param [String] bucket - this is the s3 bucket
    # @param [String] Body - this is the role of the user for whom the S3 service is being called
    #
    # @return [Result::Base]
    #
    def put_object(key, bucket, body)
      begin
        e_resp = client.put_object({
                                       bucket: bucket,
                                       key: key,
                                       body: body
                                   })
        success

      rescue => e
        return exception_with_data(
            e,
            'a_s_1',
            'exception in s3 encrypt put: ' + e.message,
            'Something went wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        )

      end
    end

    # Get object
    #
    # * Author: Aman
    # * Date: 09/10/2017
    # * Reviewed By:
    #
    # @param [String] key - this is the s3 location
    # @param [String] bucket - this is the s3 bucket
    #
    # @return [Result::Base]
    #
    def get_object(key, bucket)
      begin
        resp = client.get_object({
                                     bucket: bucket,
                                     key: key
                                 })
        success_with_data(body: resp.body.read)

      rescue => e
        return exception_with_data(
            e,
            'a_s_2',
            'exception in s3 encrypt get: ' + e.message,
            'Something went wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        )

      end
    end

    private

    # Client
    #
    # * Author: Aman
    # * Date: 09/10/2017
    # * Reviewed By:
    #
    # @return [Aws::KMS::Client]
    #
    def client
      @client ||= Aws::S3::Encryption::Client.new(
          access_key_id: access_key_id,
          secret_access_key: secret_key,
          region: region,
          encryption_key: @encryption_key
      )
    end

    # Access key
    #
    # * Author: Aman
    # * Date: 09/10/2017
    # * Reviewed By:
    #
    # @return [String] returns access key for AWS
    #
    def access_key_id
      credentials['access_key']
    end

    # Secret key
    #
    # * Author: Aman
    # * Date: 09/10/2017
    # * Reviewed By:
    #
    # @return [String] returns secret key for AWS
    #
    def secret_key
      credentials['secret_key']
    end

    # Region
    #
    # * Author: Aman
    # * Date: 09/10/2017
    # * Reviewed By:
    #
    # @return [String] returns region
    #
    def region
      GlobalConstant::Aws::Common.region
    end

    # Credentials
    #
    # * Author: Aman
    # * Date: 09/10/2017
    # * Reviewed By:
    #
    # @return [Hash] returns Hash of AWS credentials
    #
    def credentials
      @credentials ||= GlobalConstant::Aws::Common.get_credentials_for(@role)
    end

  end

end
