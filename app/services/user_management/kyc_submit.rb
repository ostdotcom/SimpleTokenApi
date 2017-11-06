module UserManagement

  class KycSubmit < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # @params [Integer] user_id (mandatory) - user id
    # @params [String] first_name (mandatory) - first name
    # @params [String] last_name (mandatory) - last name
    # @params [String] birthdate (mandatory) - birth date
    # @params [String] street_address (mandatory) - street address
    # @params [String] city (mandatory) - city
    # @params [String] state (mandatory) - state
    # @params [String] country (mandatory) - country
    # @params [String] postal_code (mandatory) - postal code
    # @params [String] ethereum_address (mandatory) - ethereum address
    # @params [String] estimated_participation_amount (mandatory) - estimated participation amount
    # @params [String] passport_number (mandatory) - passport number
    # @params [String] nationality (mandatory) - passport country
    # @params [String] passport_file_path (mandatory) - passport file
    # @params [String] selfie_file_path (mandatory) - selfie file
    #
    # @params [String] g_recaptcha_response (mandatory)
    # @params [String] remoteip (mandatory)
    #
    # @params [String] residence_proof_file_path (optional)
    #
    #
    # @return [AdminManagement::KycSubmit]
    #
    def initialize(params)

      super

      @user_id = @params[:user_id]
      @first_name = @params[:first_name] # required
      @last_name = @params[:last_name] # required
      @birthdate = @params[:birthdate] # format - 'dd/mm/yyyy'
      @street_address = @params[:street_address] # required
      @city = @params[:city] # required
      @state = @params[:state] # required
      @country = @params[:country] # required and one of allowed
      @postal_code = @params[:postal_code] # required and regex
      @ethereum_address = @params[:ethereum_address] # required and regex
      @estimated_participation_amount = @params[:estimated_participation_amount] # required and number
      @passport_number = @params[:passport_number] # required
      @nationality = @params[:nationality] # required and one of allowed
      @passport_file_path = @params[:passport_file_path] # S3 Path of PassPort File
      @selfie_file_path = @params[:selfie_file_path] # # S3 Path of Selfie File
      @residence_proof_file_path = @params[:residence_proof_file_path] # # S3 Path of residence_proof_file File
      @g_recaptcha_response = @params[:g_recaptcha_response]
      @remoteip = @params[:remoteip]

      @user_secret = nil
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

      r = check_recaptcha_before_verification
      return r unless r.success?
      Rails.logger.info('---- check_recaptcha_before_verification done')

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

      success
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
      validate_street_address
      validate_city
      validate_country
      validate_state
      validate_postal_code
      validate_ethereum_address
      validate_estimated_participation_amount
      validate_passport_number
      validate_nationality
      validate_passport_file_path
      validate_selfie_file_path
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

      # Check if user KYC is already approved
      user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)
      if user_kyc_detail.present? && (user_kyc_detail.kyc_approved? || user_kyc_detail.kyc_denied?)
        return unauthorized_access_response('um_ks_2', 'Your KYC is already approved/denied.')
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
        age = (Time.zone.now.beginning_of_day - @birthdate)
        @error_data[:birthdate] = 'Min Age required is 18' if age < 18.year
        @error_data[:birthdate] = 'Invalid Birth Date.' if age >= 200.year
        @birthdate = @birthdate.to_s(:db)
      rescue ArgumentError
        @error_data[:birthdate] = 'Invalid Birth Date.'
      end
    end

    def validate_street_address
      @street_address = @street_address.to_s.strip
      @error_data[:street_address] = 'Street Address is required.' if !@street_address.present?
    end

    def validate_city
      @city = @city.to_s.strip
      @error_data[:city] = 'City is required.' if !@city.present?
    end

    def validate_country
      @country = @country.to_s.strip
      if !@country.present? || !GlobalConstant::CountryNationality.countries.include?(@country)
        @error_data[:country] = 'Country is required.'
      end
    end

    def validate_state
      @state = @state.to_s.strip
      if !@state.present?
        @error_data[:state] = 'State is required.'
      elsif GlobalConstant::CountryNationality.disallowed_states[@country.downcase].present? && GlobalConstant::CountryNationality.disallowed_states[@country.downcase][@state.downcase].present?
        @error_data[:state] = "#{GlobalConstant::CountryNationality.disallowed_states[@country.downcase][@state.downcase]} State residents are unable to participate in the token sale. Please refer to T&Cs."
      end
    end

    def validate_postal_code
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
      @estimated_participation_amount = @estimated_participation_amount.to_s.strip
      if !Util::CommonValidator.is_numeric?(@estimated_participation_amount)
        @error_data[:estimated_participation_amount] = 'Estimated participation amount is required.'
      else
        @error_data[:estimated_participation_amount] = 'Estimated participation amount should be greater than 0' if @estimated_participation_amount.to_i <= 0
      end
    end

    def validate_passport_number
      @passport_number = @passport_number.to_s.strip
      @error_data[:passport_number] = 'Passport number is required.' if !@passport_number.present?
    end

    def validate_nationality
      @nationality = @nationality.to_s.strip
      if !@nationality.present? || !GlobalConstant::CountryNationality.nationalities.include?(@nationality)
        @error_data[:nationality] = 'Nationality is required.'
      end
    end

    def validate_passport_file_path
      @passport_file_path = @passport_file_path.to_s.strip
      @error_data[:passport_file_path] = 'Passport image is required.' if !@passport_file_path.present?
    end

    def validate_selfie_file_path
      @selfie_file_path = @selfie_file_path.to_s.strip
      @error_data[:selfie_file_path] = 'Selfie is required.' if !@selfie_file_path.present?
    end

    def validate_residence_proof_file_path
      @residence_proof_file_path = @residence_proof_file_path.to_s.strip
      if GlobalConstant::CountryNationality.is_residence_proof_mandatory?(@nationality) && !@residence_proof_file_path.present?
        @error_data[:residence_proof_file_path] = 'Residence proof is required.'
      end
    end

    # Fetch user data
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # Sets @user, @user_secret
    #
    def fetch_user_data
      @user = User.get_from_memcache(@user_id)
      return unauthorized_access_response('um_ks_3') unless @user.present? &&
          (@user.status == GlobalConstant::User.active_status)

      @user_secret = UserSecret.where(id: @user.user_secret_id).first
      return unauthorized_access_response('um_ks_4') unless @user_secret.present?

      success
    end

    # Verify recaptcha
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def check_recaptcha_before_verification
      # Check re-capcha on when verification is not yet done
      r = Recaptcha::Verify.new({
                                    'response' => @g_recaptcha_response.to_s,
                                    'remoteip' => @remoteip.to_s
                                }).perform
      Rails.logger.info('---- Recaptcha::Verify done')
      return r unless r.success?

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
          passport_number: @passport_number,
          nationality: @nationality,
          passport_file_path: @passport_file_path,
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
          passport_number: @passport_number,
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
      @user.send("set_"+GlobalConstant::User.token_sale_kyc_submitted_property)
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
      # Until the user Does Double Opt in do nothing here. In edit let it call.
      if @user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")
        BgJob.enqueue(
            KycSubmitJob,
            {
                user_id: @user_id,
                action: GlobalConstant::UserActivityLog.update_kyc_action,
                action_timestamp: Time.now.to_i
            }
        )
        Rails.logger.info('---- enqueue_job done')
      end
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
