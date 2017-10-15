module AdminManagement

  module Kyc

    class CheckDetails < ServicesBase

      # Initialize
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # @param [Integer] admin_id (mandatory) - logged in admin
      # @param [Integer] case_id (mandatory)
      #
      # @return [AdminManagement::Kyc::CheckDetails]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @user_kyc_detail_id = @params[:case_id]

        @user_kyc_detail = nil
        @user_extended_detail = nil
        @kyc_salt_e = nil
        @kyc_salt_d = nil
        @api_response_data = {}
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def perform
        r = validate
        return r unless r.success?

        r = fetch_user_kyc_detail
        return r unless r.success?

        r = fetch_user_extended_detail
        return r unless r.success?

        r = decrypt_kyc_salt
        return r unless r.success?

        set_api_response_data

        success_with_data(@api_response_data)
      end

      private

      # Fetch user kyc detail
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @user, @user_kyc_detail
      #
      def fetch_user_kyc_detail
        @user_kyc_detail = UserKycDetail.where(id: @user_kyc_detail_id).first
        return err_response('am_k_cd_1') if @user_kyc_detail.blank?

        @user = User.where(id: @user_kyc_detail.user_id).first

        success
      end

      # Fetch user extended detail
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @user_extended_detail, @kyc_salt_e
      #
      def fetch_user_extended_detail
        @user_extended_detail = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first
        return err_response('am_k_cd_2') if @user_extended_detail.blank?

        @kyc_salt_e = @user_extended_detail.kyc_salt

        success
      end

      # Decrypt kyc salt
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @kyc_salt_d
      #
      def decrypt_kyc_salt

        r = Aws::Kms.new('kyc', 'admin').decrypt(@kyc_salt_e)
        return err_response('am_k_cd_3') unless r.success?

        @kyc_salt_d = r.data[:plaintext]

        success

      end

      # Set API response data
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @api_response_data
      #
      def set_api_response_data
        @api_response_data = {
          user_detail: user_detail,
          case_detail: case_detail,
          is_case_closed: @user_kyc_detail.case_closed?
        }
      end

      # User detail
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def user_detail
        {
          first_name: @user_extended_detail.first_name,
          last_name: @user_extended_detail.last_name,
          email: @user.email,
          kyc_confirmed_at: Time.at(@user_kyc_detail.kyc_confirmed_at).strftime("%d/%m/%Y %H:%M"),

          birthdate: birthdate_d,
          passport_number: passport_number_d,
          nationality: nationality_d,
          street_address: street_address_d,
          city: city_d,
          state: state_d,
          postal_code: postal_code_d,
          country: country_d,

          passport_file_url: passport_file_url,
          self_file_url: self_file_url,
          residence_proof_file_url: residence_proof_file_url
        }
      end

      # Case detail
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Hash]
      #
      def case_detail
        {
          admin_status: @user_kyc_detail.admin_status,
          cynopsis_status: @user_kyc_detail.cynopsis_status,
          is_re_submitted: @user_kyc_detail.is_re_submitted.to_i,
          is_duplicate: @user_kyc_detail.is_duplicate.to_i,
          last_acted_by: last_acted_by
        }
      end

      # Last acted by
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # @return [String]
      #
      def last_acted_by
        (@user_kyc_detail.last_acted_by.to_i > 0) ?
          Admin.where(id: @user_kyc_detail.last_acted_by).first.name :
          ''
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def birthdate_d
        local_cipher_obj.decrypt(@user_extended_detail.birthdate).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def passport_number_d
        local_cipher_obj.decrypt(@user_extended_detail.passport_number).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def nationality_d
        local_cipher_obj.decrypt(@user_extended_detail.nationality).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def street_address_d
        local_cipher_obj.decrypt(@user_extended_detail.street_address).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def city_d
        local_cipher_obj.decrypt(@user_extended_detail.city).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def postal_code_d
        local_cipher_obj.decrypt(@user_extended_detail.postal_code).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def country_d
        local_cipher_obj.decrypt(@user_extended_detail.country).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def state_d
        local_cipher_obj.decrypt(@user_extended_detail.state).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def passport_file_url
        get_url(passport_file_path_d)
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def self_file_url
        get_url(selfie_file_path_d)
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def residence_proof_file_url
        get_url(residence_proof_file_path_d)
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def get_url(s3_path)
        return '' unless s3_path.present?

        Aws::S3Manager.new('kyc', 'admin').
          get_signed_url_for(GlobalConstant::Aws::Common.kyc_bucket, s3_path)
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def passport_file_path_d
        local_cipher_obj.decrypt(@user_extended_detail.passport_file_path).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def selfie_file_path_d
        local_cipher_obj.decrypt(@user_extended_detail.selfie_file_path).data[:plaintext]
      end

      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def residence_proof_file_path_d
        @user_extended_detail.residence_proof_file_path.present? ?
          local_cipher_obj.decrypt(@user_extended_detail.residence_proof_file_path).data[:plaintext] :
          ''
      end

      # local cipher obj
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      def local_cipher_obj
        @local_cipher_obj ||= LocalCipher.new(@kyc_salt_d)
      end

      # Error Response
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def err_response(err, display_text = 'Invalid request.')
        error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

    end

  end

end