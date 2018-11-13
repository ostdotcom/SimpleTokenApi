# frozen_string_literal: true
module GlobalConstant

  class ClientKycConfigDetail

    class << self

      # GlobalConstant::ClientKycConfigDetail

      ## Extra kyc Fields key start ###

      def text_data_type
        'text'
      end

      ## Extra Kyc Fields key end ###


      # kyc fields config for label data
      def kyc_fields_config_with_labels

        @kyc_fields_config ||= begin
          data = {}
          ::ClientKycConfigDetail.kyc_fields_config.keys.each do |kyc_field|
            data[kyc_field.to_sym] = {
                label: kyc_field.titleize
            }

          end
          data
        end
      end


      ### kyc fields Start ###

      def first_name_kyc_field
        'first_name'
      end

      def last_name_kyc_field
        'last_name'
      end

      def birthdate_kyc_field
        'birthdate'
      end

      def street_address_kyc_field
        'street_address'
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

      def postal_code_kyc_field
        'postal_code'
      end

      def ethereum_address_kyc_field
        'ethereum_address'
      end

      def document_id_number_kyc_field
        'document_id_number'
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

      def investor_proof_files_path_kyc_field
        'investor_proof_files_path'
      end

      #NOTE: Update count in param_errors for key: 'invalid_investor_proof_files_path_count'
      def max_number_of_investor_proofs_allowed
        2
      end

      ### kyc fields End ###

      def mandatory_client_fields
        [
            first_name_kyc_field,
            last_name_kyc_field,
            birthdate_kyc_field,
            country_kyc_field,
            document_id_number_kyc_field,
            nationality_kyc_field,
            document_id_file_path_kyc_field,
            selfie_file_path_kyc_field,
            residence_proof_file_path_kyc_field
        ]
      end

      def unencrypted_fields
        [
            first_name_kyc_field,
            last_name_kyc_field
        ]
      end

      def encrypted_fields
        [
            birthdate_kyc_field,
            country_kyc_field,
            nationality_kyc_field,
            ethereum_address_kyc_field,
            document_id_number_kyc_field,

            state_kyc_field,
            city_kyc_field,
            postal_code_kyc_field,
            street_address_kyc_field,
            estimated_participation_amount_kyc_field,

            document_id_file_path_kyc_field,
            selfie_file_path_kyc_field,
            residence_proof_file_path_kyc_field,
            investor_proof_files_path_kyc_field
        ]
      end

      def image_url_fields
        [
            document_id_file_path_kyc_field,
            selfie_file_path_kyc_field,
            residence_proof_file_path_kyc_field,
            investor_proof_files_path_kyc_field
        ]
      end

      def non_mandatory_fields
        [
            residence_proof_file_path_kyc_field,
            investor_proof_files_path_kyc_field
        ]
      end

    end

  end

end
