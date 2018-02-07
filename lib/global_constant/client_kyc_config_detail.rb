# frozen_string_literal: true
module GlobalConstant

  class ClientKycConfigDetail

    class << self

      ### kyc fields Start ###

      def first_name_kyc_field
        'first_name'
      end

      def last_name_kyc_field
        'last_name'
      end

      def dob_kyc_field
        'dob_name'
      end

      def stree_address_kyc_field
        'stree_address_name'
      end

      def city_kyc_field
        'city'
      end

      def state_kyc_field
        'state'
      end

      def country_kyc_field
        'country'
      end

      def zip_code_kyc_field
        'zip_code'
      end

      def ethereum_address_kyc_field
        'ethereum_address'
      end

      def document_id_number_kyc_field
        'document_id'
      end

      def nationality_kyc_field
        'nationality'
      end

      def document_id_file_path_kyc_field
        'document_id_file_path'
      end

      def selfie_file_path_kyc_field
        'selfie_file_path'
      end

      def residence_proof_file_path_kyc_field
        'residence_proof_file_path'
      end

      def estimated_participation_amount_kyc_field
        'estimated_participation_amount'
      end

      ### kyc fields End ###

      def mandatory_fields
        [
            first_name_kyc_field,
            last_name_kyc_field,
            dob_kyc_field,
            country_kyc_field,
            ethereum_address_kyc_field,
            document_id_number_kyc_field,
            nationality_kyc_field,
            document_id_file_path_kyc_field,
            selfie_file_path_kyc_field,
            residence_proof_file_path_kyc_field
        ]
      end

    end

  end

end
