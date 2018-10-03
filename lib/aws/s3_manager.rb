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

    # Minimum file size for kyc
    #
    # * Author: Pankaj
    # * Date: 28/08/2018
    # * Reviewed By:
    #
    def min_file_size
      (1024 * 200)
    end

    # Maximum file size for kyc
    #
    # * Author: Pankaj
    # * Date: 28/08/2018
    # * Reviewed By:
    #
    def max_file_size
      (1024 * 1024 * 20)
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
    # @return [Result::Base]
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
    # @return [Result::Base]
    #
    def get_presigned_post_url_for(content_type, s3_path, bucket, options = {})
      post_policy = {
          key: s3_path,
          content_type: content_type,
          signature_expiration: Time.now + 900,
          server_side_encryption: 'aws:kms',
          server_side_encryption_aws_kms_key_id: key_id,
          content_length_range: min_file_size..max_file_size # allow max 20 MB and min 200 kb
      }

      post = Aws::S3::PresignedPost.new(
          credentials_obj,
          region,
          bucket,
          post_policy
      )
    end

    # Get signed url for client assets
    #
    # * Author: Pankaj
    # * Date: 16/08/2018
    # * Reviewed By:
    #
    # @param [String] content_type - upload file content type
    # @param [String] s3_path - upload file path in bucket
    # @param [String] bucket - upload bucket
    #
    # @return [Result::Base]
    #
    def get_presigned_post_url_for_client_assets(content_type, s3_path, bucket, content_length_range)
      post_policy = {
          key: s3_path,
          content_type: content_type,
          signature_expiration: Time.now + 1800,
          acl: 'public-read',
          content_length_range: content_length_range
      }

      post = Aws::S3::PresignedPost.new(
          credentials_obj,
          region,
          bucket,
          post_policy
      )
    end

    # Get S3 Bucket object
    #
    # * Author: Pankaj
    # * Date: 28/08/2018
    # * Reviewed By:
    #
    # @param [String] bucket_name - Bucket name to load object
    #
    # @return [s3BucketObject]
    #
    def get_s3_bucket_object(bucket_name)
      resource.bucket(bucket_name)
    end

    # Get Pre-Signed url for Put file in S3
    #
    # * Author: Pankaj
    # * Date: 16/08/2018
    # * Reviewed By:
    #
    # @param [String] content_type - Uploaded file's content type
    # @param [String] s3_path - File path to upload in S3
    # @param [String] bucket - upload bucket
    #
    # @return [Result::Base]
    #
    def get_presigned_put_url_for(s3_name, bucket, content_type)
      params = {
          bucket: bucket,
          key: s3_name
      }

      options={
          content_type: content_type,
          server_side_encryption: 'aws:kms',
          ssekms_key_id: key_id
      }

      presigner = Aws::S3::Presigner.new({client: client})
      u = presigner.presigned_url(:put_object, params.merge(options))
      # uri = URI.parse(u)
      # uri
      # r = Net::HTTP.start(uri.host, :use_ssl => true) do |http|
      #   http.send_request("PUT", uri.request_uri, File.read(file_path), {
      #       # This is required, or Net::HTTP will add a default unsigned content-type.
      #        "content-type" => content_type
      #   })
      #
      # end
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

    private

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