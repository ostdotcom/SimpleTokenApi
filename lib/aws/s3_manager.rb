module Aws

  class S3Manager

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
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
    # * Reviewed By: Sunil
    #
    # @param [String] bucket - bucket name
    # @param [String] s3_path - file path in bucket
    # @param [Hash] options - options for signed url
    #
    # @return [Resul::Base]
    #
    def get_signed_url_for(bucket, s3_path, options = {})
      signer = Aws::S3::Presigner.new({client: client})
      params = {
          bucket: bucket,
          key: s3_path
      }

      signer.presigned_url(
          :get_object,
          params.merge(options)
      )
    end

    # Get signed url for
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
    #
    # @param [String] content_type - upload file content type
    # @param [String] s3_path - upload file path in bucket
    # @param [String] bucket - upload bucket
    # @param [Hash] options - extra options
    #
    # @return [Resul::Base]
    #
    def get_presigned_post_url_for(content_type, s3_path, bucket, options = {})
      max_size = options[:max_size].present? ? options[:max_size] : (1024 * 1024 * 20)
      post_policy = {
          key: s3_path,
          content_type: content_type,
          signature_expiration: Time.now + 1800,
          server_side_encryption: 'aws:kms',
          server_side_encryption_aws_kms_key_id: key_id,
          content_length_range: (1024 * 200)..max_size # allow max 20 MB and min 200 kb
      }

      post = Aws::S3::PresignedPost.new(
          credentials_obj,
          region,
          bucket,
          post_policy
      )
    end

    def upload_file_presigned_url(s3_name, file_path)
      s3 = resource
      obj = s3.bucket(GlobalConstant::Aws::Common.kyc_bucket).object(s3_name)
      url = URI.parse(obj.presigned_url(:put, {
          server_side_encryption: 'aws:kms',
          ssekms_key_id: key_id,
          content_type: 'image/jpg',
          content_length: (1024)
      }))

      puts url
      Net::HTTP.start(url.host) do |http|
        http.send_request("PUT", url.request_uri, File.read(file_path), {
          # This is required, or Net::HTTP will add a default unsigned content-type.
          "content-type" => "image/jpg",
        })
      end
    end

    # upload data in s3
    #
    # * Author: Aman
    # * Date: 21/12/2017
    # * Reviewed By: Sunil
    #
    # @param [String] s3_path - upload file path in bucket
    # @param [File] body - upload file
    # @param [String] bucket - upload bucket
    # @param [Hash] options - extra options
    #
    def store(s3_path, body, bucket, options = {})
      params = {
          key: s3_path,
          body: body,
          bucket: bucket
      }
      options.merge!({server_side_encryption: 'aws:kms',
                      ssekms_key_id: key_id,
                      acl: "private"
                     })

      client.put_object(params.merge(options))

    end

    # Download an object to disk
    #
    # * Author: Aman
    # * Date: 21/12/2017
    # * Reviewed By: Sunil
    #
    # @param [String] s3_path - upload file path in bucket
    # @param [String] local_path - local file path for download
    # @param [String] bucket - upload bucket
    #
    def get(local_path, s3_path, bucket)
      client.get_object(
          response_target: local_path,
          bucket: bucket,
          key: s3_path)
    end

    # private

    # Client
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Aws::KMS::Client]
    #
    def client
      @client ||= Aws::S3::Client.new(
          access_key_id: access_key,
          secret_access_key: secret_key,
          region: region
      )
    end

    def resource
      @resource ||= Aws::S3::Resource.new(
          access_key_id: access_key,
          secret_access_key: secret_key,
          region: region
      )
    end

    # Aws credential object
    #
    # * Author: Kedar
    # * Date: 15/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Aws::Credentials]
    #
    def credentials_obj
      @credentials_obj ||= Aws::Credentials.new(
          access_key,
          secret_key
      )
    end

    # Access key
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
    #
    # @return [String] returns access key for AWS
    #
    def access_key
      credentials['access_key']
    end

    # Secret key
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
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
    # * Reviewed By: Sunil
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
    # * Reviewed By: Sunil
    #
    # @return [Hash] returns Hash of AWS credentials
    #
    def credentials
      @credentials ||= GlobalConstant::Aws::Common.get_credentials_for(@role)
    end

    # Key id
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [String] returns the key id
    #
    def key_id
      GlobalConstant::Aws::Kms.get_key_id_for(@purpose)
    end

  end

end