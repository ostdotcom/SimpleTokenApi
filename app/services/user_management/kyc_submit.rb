module UserManagement

  class KycSubmit < ServicesBase

    S3_DOCUMENT_PATH_REGEX = /\A[A-Z0-9\/]+\Z/i

    # Initialize
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [Integer] user_id (mandatory) - user id
    # @params [Integer] client_id (mandatory) - client id
    # @params [String] first_name (mandatory) - first name
    # @params [String] last_name (mandatory) - last name
    # @params [String] birthdate (mandatory) - birth date
    # @params [String] country (mandatory) - country
    # @params [String] ethereum_address (mandatory) - ethereum address
    # @params [String] document_id_number (mandatory) - document_id number
    # @params [String] nationality (mandatory) - document_id country
    # @params [String] document_id_file_path (mandatory) - document_id file
    # @params [String] selfie_file_path (mandatory) - selfie file
    #
    # @params [String] postal_code (optional) - postal code
    # @params [String] street_address (optional) - street address
    # @params [String] city (optional) - city
    # @params [String] state (optional) - state
    # @params [String] residence_proof_file_path (optional)
    # @params [String] estimated_participation_amount (optional) - estimated participation amount
    #
    #
    # @return [AdminManagement::KycSubmit]
    #
    def initialize(params)

      super

      @user_id = @params[:user_id]
      @client_id = @params[:client_id]
      @first_name = @params[:first_name] # required
      @last_name = @params[:last_name] # required
      @birthdate = @params[:birthdate] # format - 'dd/mm/yyyy'
      @street_address = @params[:street_address]
      @city = @params[:city]
      @state = @params[:state]
      @country = @params[:country] # required and one of allowed
      @postal_code = @params[:postal_code]
      @ethereum_address = @params[:ethereum_address] # required and regex
      @document_id_number = @params[:document_id_number] # required
      @nationality = @params[:nationality] # required and one of allowed
      @document_id_file_path = @params[:document_id_file_path] # S3 Path of document_id File
      @selfie_file_path = @params[:selfie_file_path] # # S3 Path of Selfie File
      @residence_proof_file_path = @params[:residence_proof_file_path] # # S3 Path of residence_proof_file File
      @estimated_participation_amount = @params[:estimated_participation_amount]

      @client = nil
      @client_token_sale_details = nil
      @client_kyc_config_detail = nil
      @user = nil
      @kyc_salt_d = nil
      @kyc_salt_e = nil

      @error_data = {}

    end

    # Perform
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?
      Rails.logger.info('---- validate_and_sanitize done')

      r = fetch_user_data
      return r unless r.success?
      Rails.logger.info('---- fetch_user_data done')

      r = generate_new_kyc_salt
      return r unless r.success?
      Rails.logger.info('---- generate_new_kyc_salt done')

      r = create_user_extended_details
      return r unless r.success?
      Rails.logger.info('---- create_user_extended_details done')

      r = update_user
      return r unless r.success?
      Rails.logger.info('---- update_user done')

      enqueue_job

      success_with_data({user_id: @user_id})
    end

    private

    # Validate
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      # Sanitize fields, validate and assign error
      validate_first_name
      validate_last_name
      validate_birthdate
      validate_country
      validate_ethereum_address
      validate_document_id_number
      validate_nationality
      validate_document_id_file_path
      validate_selfie_file_path

      @client_kyc_config_detail = ClientKycConfigDetail.get_from_memcache(@client_id)

      return error_with_data(
          'um_ks_5',
          'Invalid Request',
          'Invalid Request',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client_kyc_config_detail.blank?

      validate_estimated_participation_amount
      validate_street_address
      validate_city
      validate_state
      validate_postal_code
      validate_residence_proof_file_path

      # IF error, return
      return error_with_data(
          'um_ks_1',
          'Invalid Parameters.',
          'There were some errors in your KYC. Please correct and resubmit',
          GlobalConstant::ErrorAction.default,
          {},
          @error_data
      ) if @error_data.present?

      # NOTE: To be on safe side, check for generic errors as well
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)

      return error_with_data(
          'um_ks_6',
          'The token sale ended, it is no longer possible to submit personal information.',
          'The token sale ended, it is no longer possible to submit personal information.',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client_token_sale_details.has_token_sale_ended?

      # Check if user KYC is already approved
      user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)

      if user_kyc_detail.present?
        return unauthorized_access_response('um_ks_2', 'Invalid User') if user_kyc_detail.client_id != @client_id

        return error_with_data(
            'um_ks_3',
            'Your KYC is already approved/denied.',
            'Your KYC is already approved/denied.',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if (user_kyc_detail.kyc_approved? || user_kyc_detail.kyc_denied?)

      end
      success
    end

    # Field validation
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_first_name
      @first_name = @first_name.to_s.strip
      @error_data[:first_name] = 'First Name is required.' if !@first_name.present?
    end

    def validate_last_name
      @last_name = @last_name.to_s.strip
      @error_data[:last_name] = 'Last Name is required.' if !@last_name.present?
    end

    def validate_birthdate
      begin
        @birthdate = @birthdate.to_s.strip
        @birthdate = Time.zone.strptime(@birthdate, "%d/%m/%Y")
        # age = (Time.zone.now.beginning_of_day - @birthdate)
        # @error_data[:birthdate] = 'Min Age required is 18' if age < 18.year
        # @error_data[:birthdate] = 'Invalid Birth Date.' if age >= 200.year
        @birthdate = @birthdate.to_s(:db)
      rescue ArgumentError
        @error_data[:birthdate] = 'Invalid Birth Date.'
      end
    end

    def validate_street_address
      if !@client_kyc_config_detail.kyc_fields_array.include?(GlobalConstant::ClientKycConfigDetail.stree_address_kyc_field)
        @street_address = nil
        return
      end
      @street_address = @street_address.to_s.strip
      @error_data[:street_address] = 'Street Address is required.' if !@street_address.present?
    end

    def validate_city
      if !@client_kyc_config_detail.kyc_fields_array.include?(GlobalConstant::ClientKycConfigDetail.city_kyc_field)
        @city = nil
        return
      end

      @city = @city.to_s.strip
      @error_data[:city] = 'City is required.' if !@city.present?
    end

    def validate_country
      @country = @country.to_s.strip.upcase
      if !@country.present? || !GlobalConstant::CountryNationality.countries.include?(@country)
        @error_data[:country] = 'Country is required.'
      end
    end

    def validate_state
      if !@client_kyc_config_detail.kyc_fields_array.include?(GlobalConstant::ClientKycConfigDetail.state_kyc_field)
        @state = nil
        return
      end

      @state = @state.to_s.strip
      @error_data[:state] = 'State is required.' if @state.blank?
      # GlobalConstant::CountryNationality.disallowed_states[@country.downcase].present? && GlobalConstant::CountryNationality.disallowed_states[@country.downcase][@state.downcase].present?
      #  @error_data[:state] = "#{GlobalConstant::CountryNationality.disallowed_states[@country.downcase][@state.downcase]} State residents are unable to participate in the token sale. Please refer to T&Cs."
    end

    def validate_postal_code
      if !@client_kyc_config_detail.kyc_fields_array.include?(GlobalConstant::ClientKycConfigDetail.postal_code_kyc_field)
        @postal_code = nil
        return
      end

      @postal_code = @postal_code.to_s.strip
      @error_data[:postal_code] = 'Postal Code is required.' if !@postal_code.present?
    end

    def validate_ethereum_address
      @ethereum_address = Util::CommonValidator.sanitize_ethereum_address(@ethereum_address)

      unless Util::CommonValidator.is_ethereum_address?(@ethereum_address)
        @error_data[:ethereum_address] = 'Invalid ethereum address.'
      end
    end

    def validate_estimated_participation_amount
      if !@client_kyc_config_detail.kyc_fields_array.include?(GlobalConstant::ClientKycConfigDetail.estimated_participation_amount_kyc_field)
        @estimated_participation_amount = nil
        return
      end

      if !Util::CommonValidator.is_numeric?(@estimated_participation_amount)
        @error_data[:estimated_participation_amount] = 'Estimated participation amount is required.'
      else
        @error_data[:estimated_participation_amount] = 'Estimated participation amount should be greater than 0' if @estimated_participation_amount.to_i <= 0
      end
    end

    def validate_document_id_number
      @document_id_number = @document_id_number.to_s.strip.downcase
      @error_data[:document_id_number] = 'Identification document number is required.' if !@document_id_number.present?
    end

    def validate_nationality
      @nationality = @nationality.to_s.strip.upcase
      if !@nationality.present? || !GlobalConstant::CountryNationality.nationalities.include?(@nationality)
        @error_data[:nationality] = 'Nationality is required.'
      end
    end

    def validate_document_id_file_path
      @document_id_file_path = @document_id_file_path.to_s.strip
       if !@document_id_file_path.present?
         @error_data[:document_id_file_path] = 'Identification document image is required.'
       else
         @error_data[:document_id_file_path] = 'Invalid S3 path for Identification document image' if !(@document_id_file_path =~ S3_DOCUMENT_PATH_REGEX)
       end
    end

    def validate_selfie_file_path
      @selfie_file_path = @selfie_file_path.to_s.strip
       if !@selfie_file_path.present?
         @error_data[:selfie_file_path] = 'Selfie is required.'
       else
         @error_data[:selfie_file_path] = 'Invalid S3 path for Selfie' if !(@selfie_file_path =~ S3_DOCUMENT_PATH_REGEX)
       end
    end

    def validate_residence_proof_file_path
      @residence_proof_file_path = @residence_proof_file_path.to_s.strip
      if @client_kyc_config_detail.residency_proof_nationalities.include?(@nationality) && !@residence_proof_file_path.present?
        @error_data[:residence_proof_file_path] = 'Residence proof is required.'
      end

      if @residence_proof_file_path.present?
        @error_data[:residence_proof_file_path] = 'Invalid S3 path for residence proof file' if !(@residence_proof_file_path =~ S3_DOCUMENT_PATH_REGEX)
      end

    end

    # Fetch user data
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # Sets @user
    #
    def fetch_user_data
      @user = User.get_from_memcache(@user_id)
      return unauthorized_access_response('um_ks_4') unless @user.present? && @user.client_id == @client_id &&
          (@user.status == GlobalConstant::User.active_status)

      success
    end

    # Generate new KYC salt
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # Sets @kyc_salt_d, @kyc_salt_e
    #
    def generate_new_kyc_salt

      r = Aws::Kms.new('kyc', 'user').generate_data_key
      return r unless r.success?

      @kyc_salt_d = r.data[:plaintext]
      @kyc_salt_e = r.data[:ciphertext_blob]

      success
    end

    # Create user extended details
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    def create_user_extended_details

      user_extended_details_params = {
          user_id: @user_id,
          first_name: @first_name,
          last_name: @last_name,
          kyc_salt: @kyc_salt_e
      }

      md5_user_extended_details_params = {
          user_id: @user_id
      }

      data_to_encrypt = {
          birthdate: @birthdate,
          street_address: @street_address,
          city: @city,
          state: @state,
          country: @country,
          postal_code: @postal_code,
          ethereum_address: @ethereum_address,
          estimated_participation_amount: @estimated_participation_amount,
          document_id_number: @document_id_number,
          nationality: @nationality,
          document_id_file_path: @document_id_file_path,
          selfie_file_path: @selfie_file_path,
          residence_proof_file_path: @residence_proof_file_path
      }

      data_to_md5 = {
          birthdate: @birthdate,
          street_address: @street_address,
          city: @city,
          state: @state,
          country: @country,
          postal_code: @postal_code,
          ethereum_address: @ethereum_address,
          estimated_participation_amount: @estimated_participation_amount,
          document_id_number: @document_id_number,
          nationality: @nationality
      }

      data_to_encrypt.each do |key, value|
        next if value.blank?
        r = encryptor_obj.encrypt(value)
        return r unless r.success?
        user_extended_details_params[key.to_sym] = r.data[:ciphertext_blob]
      end

      data_to_md5.each do |key, value|
        md5_user_extended_details_params[key.to_sym] = Md5UserExtendedDetail.get_hashed_value(value)
      end

      user_extended_detail = UserExtendedDetail.create!(user_extended_details_params)

      md5_user_extended_details_params.merge!(user_extended_detail_id: user_extended_detail.id)

      Md5UserExtendedDetail.create!(md5_user_extended_details_params)

      success
    end

    # Encryptor obj
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    def encryptor_obj
      @encryptor_obj ||= LocalCipher.new(@kyc_salt_d)
    end

    # Update User Kyc Submitted Property
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def update_user
      @user.send("set_" + GlobalConstant::User.token_sale_kyc_submitted_property)
      # @user.send("set_"+GlobalConstant::User.token_sale_double_optin_mail_sent_property)
      @user.save! if @user.changed?
      success
    end

    # Do remaining task in sidekiq
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    def enqueue_job
      #  todo: "KYCaaS-Changes"
      # if !@user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")
      #
      #   BgJob.enqueue(
      #       OnBTSubmitJob,
      #       {
      #           user_id: @user_id
      #       }
      #   )
      #   Rails.logger.info('---- enqueue_job OnBTSubmitJob done')
      # else
      #
      #   BgJob.enqueue(
      #       KycSubmitJob,
      #       {
      #           user_id: @user_id,
      #           action: GlobalConstant::UserActivityLog.update_kyc_action,
      #           action_timestamp: Time.now.to_i
      #       }
      #   )
      #   Rails.logger.info('---- enqueue_job KycSubmitJob done')
      # end

      BgJob.enqueue(
          KycSubmitJob,
          {
              user_id: @user_id,
              action: GlobalConstant::UserActivityLog.update_kyc_action,
              action_timestamp: Time.now.to_i
          }
      )
      Rails.logger.info('---- enqueue_job KycSubmitJob done')

    end

    # Unauthorized access response
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # @param [String] err
    # @param [String] display_text
    #
    # @return [Result::Base]
    #
    def unauthorized_access_response(err, display_text = 'Unauthorized access. Please login again.')
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
