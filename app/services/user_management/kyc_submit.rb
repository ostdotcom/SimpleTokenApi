module UserManagement

  class KycSubmit < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # @param [Integer] user_id (mandatory) - user id
    # @param [String] first_name (mandatory) - first name
    # @param [String] last_name (mandatory) - last name
    # @param [String] birthdate (mandatory) - birth date
    # @param [String] street_address (mandatory) - street address
    # @param [String] city (mandatory) - city
    # @param [String] state (mandatory) - state
    # @param [String] country (mandatory) - country
    # @param [String] postal_code (mandatory) - postal code
    # @param [String] ethereum_address (mandatory) - ethereum address
    # @param [String] estimated_participation_amount (mandatory) - estimated participation amount
    # @param [String] passport_number (mandatory) - passport number
    # @param [String] nationality (mandatory) - passport country
    # @param [String] passport_file_path (mandatory) - passport file
    # @param [String] selfie_file_path (mandatory) - selfie file
    #
    # @return [AdminManagement::KycSubmit]
    #
    def initialize(params)

      super

      @user_id = @params[:user_id]
      @first_name = @params[:first_name] # required
      @last_name = @params[:last_name] # required
      @birthdate = @params[:birthdate] # format - '02-FEB-2001'
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

      r = validate
      return r unless r.success?

      r = fetch_user_data
      return r unless r.success?

      r = generate_new_kyc_salt
      return r unless r.success?

      r = create_user_extended_details
      return r unless r.success?

      r = update_user
      return r unless r.success?

      enqueue_job

      success

    end

    private

    # Validate
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate

      r = super
      return r unless r.success?

      # apply custom validations.
      @error_data[:first_name] = "First Name is required." unless @first_name.present?

      @error_data[:last_name] = "Last Name is required." unless @last_name.present?

      begin
        Date.parse(@birthdate)
      rescue ArgumentError
        @error_data[:birthdate] = "Invalid Birth Date."
      end

      @error_data[:street_address] = "Street Address is required." unless @street_address.present?

      @error_data[:city] = "City is required." unless @city.present?

      @error_data[:state] = "State is required." unless @state.present?

      @error_data[:country] = "City is required." unless @country.present?

      @error_data[:ethereum_address] = "Invalid ethereum address." unless Util::CommonValidator.is_euthereum_address?(@ethereum_address)

      return error_with_data(
          'um_ks_1',
          'Invalid Parameters.',
          'Invalid Parameters.',
          GlobalConstant::ErrorAction.default,
          {},
          @error_data
      ) if @error_data.present?

      success

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

      @user = User.where(id: @user_id).first

      unless @user.present? && (@user.status == GlobalConstant::User.active_status)
        return unauthorized_access_response('um_ks_2')
      end

      @user_secret = UserSecret.where(id: @user.user_secret_id).first

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
        last_name: @last_name
      }

      md5_user_extended_details_params = {user_id: @user_id, kyc_salt: @kyc_salt_e}

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
          selfie_file_path: @selfie_file_path,
          passport_file_path: @passport_file_path,
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
        md5_user_extended_details_params[key.to_sym] = Digest::MD5.hexdigest(value.to_s.downcase)
      end

      user_extended_detail = UserExtendedDetail.create!(user_extended_details_params)

      md5_user_extended_details_params.merge!(user_extended_detail_id: user_extended_detail.id)

      Md5UserExtendedDetail.create!(md5_user_extended_details_params)

      success

    end

    # Update User Kyc Submitted Property
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def update_user
      @user.send("set_"+GlobalConstant::User.token_sale_kyc_submitted_property)
      @user.save! if @user.changed?
      success
    end

    def enqueue_job
      return unless @user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")

      BgJob.enqueue(
        KycSubmitJob,
        {
          user_id: @user_id,
          is_re_submit: true
        }
      )
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

    # S3 encryptor obj
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    def s3_encryptor_obj
      @s3_encryptor_obj ||= Aws::S3Encryption.new(@kyc_salt_d, 'user')
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
