module Aws

  class OcrService

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 04/06/2018
    # * Reviewed By:
    #
    # @return [Aws::OcrService]
    #
    def initialize()

    end

    # Get Aws Rekognition object
    #
    # * Author: Pankaj
    # * Date: 04/06/2018
    # * Reviewed By:
    #
    # @return [Aws::Rekognition::Client]
    #
    def client
      @client ||= Aws::Rekognition::Client.new(
        access_key_id: access_key_id,
        secret_access_key: secret_key,
        region: region
      )
    end

    # Temproary method to get kyc file urls
    #
    # * Author: Pankaj
    # * Date: 04/06/2018
    # * Reviewed By:
    #
    def kyc_file_urls(user_id)
      ukc = UserKycDetail.where(user_id: user_id).first

      return error_with_data("Not found", "User not found", "User not found", "", "") if ukc.nil?

      ued = UserExtendedDetail.where(id: ukc.user_extended_detail_id).first

      r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)

      kyc_salt_d = r.data[:plaintext]

      local_cipher_obj = LocalCipher.new(kyc_salt_d)

      data = {}
      data[:doc_path] = local_cipher_obj.decrypt(ued.document_id_file_path).data[:plaintext] if ued.document_id_file_path.present?
      data[:selfie_path] = local_cipher_obj.decrypt(ued.selfie_file_path).data[:plaintext] if ued.selfie_file_path.present?
      data[:bucket] = GlobalConstant::Aws::Common.kyc_bucket

      success_with_data(data)
    end

    def make_params(source_image, target_image)
      return {
          source_image: {
              s3_object: {
                  bucket: GlobalConstant::Aws::Common.kyc_bucket,
                  name: "2/i/dc132c0c9f6518f16b92385ba84cae96",
              }
          },
          target_image: {
              s3_object: {
                  bucket: GlobalConstant::Aws::Common.kyc_bucket,
                  name: "2/i/f411986f93714c5ef0c2a1ca0bbd83dd",
              }
          },
      }
    end

    private

    # Access key
    #
    # * Author: Pankaj
    # * Date: 04/06/2018
    # * Reviewed By:
    #
    # @return [String] returns access key for AWS
    #
    def access_key_id
      credentials['access_key']
    end

    # Secret key
    #
    # * Author: Pankaj
    # * Date: 04/06/2018
    # * Reviewed By:
    #
    # @return [String] returns secret key for AWS
    #
    def secret_key
      credentials['secret_key']
    end

    # Region
    #
    # * Author: Pankaj
    # * Date: 04/06/2018
    # * Reviewed By:
    #
    # @return [String] returns region
    #
    def region
      GlobalConstant::Aws::Common.region
    end

    # Credentials
    #
    # * Author: Pankaj
    # * Date: 04/06/2018
    # * Reviewed By:
    #
    # @return [Hash] returns Hash of AWS credentials
    #
    def credentials
      @credentials ||= GlobalConstant::Aws::Common.get_credentials_for('admin')
    end

  end

end