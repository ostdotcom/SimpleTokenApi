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
    # @param [String] passport_country (mandatory) - passport country
    # @param [String] passport_file (mandatory) - passport file
    # @param [String] selfie_file (mandatory) - selfie file
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
      @passport_country = @params[:passport_country] # required and one of allowed
      @passport_file = @params[:passport_file] # required and minimum and max size
      @selfie_file = @params[:selfie_file] # required and minimum and max size

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

      success_with_data(user_id: @user_id)
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

      @error_data[:postal_code] = "Invalid Postal Code." unless Util::CommonValidator.is_numeric?(@postal_code)

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

      return error_with_data(
        'um_ks_2',
        'Kyc Already Added.',
        'Kyc Already Added.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if UserExtendedDetail.where(user_id: @user_id).first.present?

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
      user_extended_details_params = {user_id: @user_id}
      md5_user_extended_details_params = {user_id: @user_id}

      data_to_encrypt = {
        first_name: @first_name,
        last_name: @last_name,
        kyc_salt: @kyc_salt_e,
        birthdate: @birthdate,
        street_address: @street_address,
        city: @city,
        state: @state,
        country: @country,
        postal_code: @postal_code,
        ethereum_address: @ethereum_address,
        estimated_participation_amount: @estimated_participation_amount,
        passport_number: @passport_number,
        passport_country: @passport_country
      }

      data_to_encrypt.each do |key, value|
        r = encryptor_obj.encrypt(value)
        return r unless r.success?
        user_extended_details_params[key.to_sym] = r.data[:ciphertext_blob]
        md5_user_extended_details_params[key.to_sym] = Digest::MD5.hexdigest(value.to_s.downcase)
      end

      @passport_url = get_file_path('passport')
      @selfie_url = get_file_path('selfie')

      r = upload_passport_image
      return r unless r.success?

      r = upload_selfie_image
      return r unless r.success?

      user_extended_details_params.merge!(passport_url: @passport_url, selfie_url: @selfie_url)

      ued = UserExtendedDetail.create!(user_extended_details_params)

      md5_user_extended_details_params.merge!(user_extended_detail_id: ued.id)

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

    # upload passport image
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    def upload_passport_image
      r = s3_encryptor_obj.put_object(@passport_url, bucket, @passport_file)
      return r unless r.success?

      success
    end

    # upload selfie image
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    def upload_selfie_image
      r = s3_encryptor_obj.put_object(@selfie_url, bucket, @selfie_file)
      return r unless r.success?

      success
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

    # KYC Bucket
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    def bucket
      GlobalConstant::Aws::Common.kyc_bucket
    end

    # Get file path for
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # @param [String] file_type
    #
    def get_file_path(file_type)
      file_name = Digest::MD5.hexdigest("#{Time.now.to_i}-#{file_type}-#{@user.id}-#{@user_secret.id}-#{@user.password}")
      "kyc/i/#{file_name}"
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
