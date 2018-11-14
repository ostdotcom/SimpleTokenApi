module UserManagement
  module KycDetail
    class Get < ServicesBase

      IMAGES_URL_EXPIRY_TIMESTAMP_INTERVAL = 12.hours.to_i
      # Initialize
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      # @param [Integer] user_id (mandatory) - user id
      #
      #
      # @return [UserManagement::KycDetail::Get]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @user_id = @params[:user_id]

        @user_kyc_detail = nil
        @user_extended_detail_obj = nil
        @client_kyc_detail_api_activations = nil

        @user_extended_detail = {}
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        r = fetch_user_kyc_detail
        return r unless r.success?

        fetch_user_extended_detail

        fetch_client_kyc_detail_api_activations

        get_user_extended_detail_data

        success_with_data(service_response_data)
      end

      private

      # Valdiate and sanitize
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets client
      #
      def validate_and_sanitize

        r = validate
        return r unless r.success?

        r = validate_and_sanitize_params
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        success
      end

      # validate and sanitize params
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      #
      def validate_and_sanitize_params
        return error_with_identifier('invalid_api_params',
                                     'um_kd_g_vasp_1',
                                     ['invalid_user_id']
        ) unless Util::CommonValidateAndSanitize.is_integer?(@user_id)
        @user_id = @user_id.to_i

        success
      end

      # fetch and validate user kyc detail
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets @user_kyc_detail
      #
      def fetch_user_kyc_detail
        @user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)

        return error_with_identifier('resource_not_found',
                                     'um_kd_g_fukd_1'
        ) if (@user_kyc_detail.blank? || (@user_kyc_detail.status != GlobalConstant::UserKycDetail.active_status) ||
            (@user_kyc_detail.client_id != @client_id))

        success
      end

      # fetch and validate user extended detail
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets @user_extended_details
      #
      def fetch_user_extended_detail
        @user_extended_detail_obj = UserExtendedDetail.get_from_memcache(@user_kyc_detail.user_extended_detail_id)
      end

      # fetch and validate client kyc detail api activations
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets @client_kyc_detail_api_activations
      #
      def fetch_client_kyc_detail_api_activations
        @client_kyc_detail_api_activations = ClientKycDetailApiActivation.get_last_active_from_memcache(@client_id)
      end

      # Get Allowed Fields for User Extended Detail Hash
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      def allowed_kyc_fields
        @allowed_kyc_fields ||= @client_kyc_detail_api_activations.present? ? @client_kyc_detail_api_activations.kyc_fields_array : []
      end

      # Get Allowed extra kyc fields for User Extended Detail Hash
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      def allowed_extra_kyc_fields
        @allowed_extra_kyc_fields ||= @client_kyc_detail_api_activations.present? ? @client_kyc_detail_api_activations.extra_kyc_fields : []
      end

      # Get Local Cipher Obj
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      def local_cipher_obj
        @local_cipher_obj ||= begin
          kyc_salt_e = @user_extended_detail_obj.kyc_salt
          r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
          throw 'Unable to decrypt data' unless r.success?

          kyc_salt_d = r.data[:plaintext]
          LocalCipher.new(kyc_salt_d)
        end
      end


      # Get User Extended Detail Data
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # sets @user_extended_detail
      #
      def get_user_extended_detail_data

        allowed_kyc_fields.each do |field_name|
          if GlobalConstant::ClientKycConfigDetail.unencrypted_fields.include?(field_name)
            @user_extended_detail[field_name.to_sym] = @user_extended_detail_obj[field_name]
          elsif GlobalConstant::ClientKycConfigDetail.encrypted_fields.include?(field_name)

            if GlobalConstant::ClientKycConfigDetail.non_mandatory_fields.include?(field_name) && @user_extended_detail_obj[field_name].blank?
              if field_name == GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field
                for i in 1..GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed
                  @user_extended_detail[field_name.to_sym] ||= []
                end
              else
                @user_extended_detail[field_name.to_sym] = nil
              end
              next
            end

            decrypted_data = local_cipher_obj.decrypt(@user_extended_detail_obj[field_name]).data[:plaintext]

            if GlobalConstant::ClientKycConfigDetail.image_url_fields.include?(field_name)
              if field_name == GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field
                for i in 1..GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed
                  @user_extended_detail[field_name.to_sym] ||= []
                  @user_extended_detail[field_name.to_sym] << get_url(decrypted_data[i - 1])
                end
              else
                @user_extended_detail[field_name.to_sym] = get_url(decrypted_data)
              end
            else
              @user_extended_detail[field_name.to_sym] = decrypted_data
            end

          else
            throw "invalid kyc field-#{field_name}"
          end
        end

        extra_kyc_fields = {}

        if @user_extended_detail_obj[:extra_kyc_fields].present?
          extra_kyc_fields = local_cipher_obj.decrypt(@user_extended_detail_obj[:extra_kyc_fields]).data[:plaintext]
        end

        allowed_extra_kyc_fields.each do |field_name|
          @user_extended_detail[field_name.to_sym] = extra_kyc_fields[field_name.to_sym]
        end


        @user_extended_detail.merge!({id: @user_extended_detail_obj.id, created_at: @user_extended_detail_obj.created_at.to_i})
      end

      # Get The Signed URL
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      def get_url(s3_path)
        return nil unless s3_path.present?
        s3_manager_obj.get_signed_url_for(GlobalConstant::Aws::Common.kyc_bucket, s3_path, {expires_in: IMAGES_URL_EXPIRY_TIMESTAMP_INTERVAL})
      end

      # S3 Job Manager
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # sets @s3_manager_obj
      #
      def s3_manager_obj
        @s3_manager_obj ||= Aws::S3Manager.new('kyc', 'admin')
      end


      # Format service response
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      def service_response_data
        {
            user_extended_detail: @user_extended_detail
        }
      end

    end
  end
end
