module UserManagement

  class KycSubmit < ServicesBase

    def initialize(params)
      super

      @user_id = @params[:user_id]

      @first_name = @params[:first_name]
      @last_name = @params[:last_name]

      @birthdate = @params[:birthdate]
      @street_address = @params[:street_address]
      @city = @params[:city]
      @state = @params[:state]
      @country = @params[:country]
      @postal_code = @params[:postal_code]
      @ethereum_address = @params[:ethereum_address]
      @estimated_participation_amount = @params[:estimated_participation_amount]
      @passport_number = @params[:passport_number]
      @passport_file = @params[:passport_file]
      @selfie_file = @params[:selfie_file]

      @user_secret = nil
      @user = nil
      @kyc_salt_d = nil
    end


    def perform

      r = validate
      return r unless r.success?

      r = fetch_user_data
      return r unless r.success?

      r = generate_new_kyc_salt
      return r unless r.success?

      r = update_user_data
      return r unless r.success?

      r = create_user_extended_details
      return r unless r.success?

      success_with_data(user_id: @user_id)
    end

    private

    def fetch_user_data
      @user = User.where(id: @user_id).first

      return error_with_data(
          'um_su_1',
          'Invalid User',
          'Invalid User',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @user.blank?

      @user_secret = UserSecret.where(id: @user.user_secret_id).first

      success
    end


    def generate_new_kyc_salt
      r = Aws::Kms.new('kyc', 'user').generate_data_key
      return r unless r.success?

      @kyc_salt_d = r.data[:plaintext]

      @user_secret.kyc_salt = r.data[:ciphertext_blob]

      success
    end

    def encryptor_obj
      @encryptor_obj ||= LocalCipher.new(@kyc_salt_d)
    end

    def update_user_data
      @user.first_name = @first_name
      @user.last_name = @last_name
      success
    end

    def create_user_extended_details
      user_extended_details_params = {user_id: @user_id}

      data_to_encrypt = {
          birthdate: @birthdate,
          street_address: @street_address,
          city: @city,
          state: @state,
          country: @country,
          postal_code: @postal_code,
          ethereum_address: @ethereum_address,
          estimated_participation_amount: @estimated_participation_amount,
          passport_number: @passport_number
      }

      data_to_encrypt.each do |key, value|
        r = encryptor_obj.encrypt(value)
        return r unless r.success?
        user_extended_details_params[key.to_sym] = r.data[:ciphertext_blob]
      end

      r = upload_passport_image
      return r unless r.success?

      r = upload_selfie_image
      return r unless r.success?

      user_extended_details_params.merge!(passport_url: @passport_url, selfie_url: @selfie_url)

      EstablishSimpleTokenUserDbConnection.transaction do
        UserExtendedDetail.create!(user_extended_details_params)
        @user_secret.save!
        @user.save!
      end

      success
    end

    def upload_passport_image
      @passport_url = get_file_path('passport')
      r = s3_encryptor_obj.put_object(@passport_url, bucket, @passport_file)
      return r unless r.success?
      success
    end

    def upload_selfie_image
      @selfie_url = get_file_path('selfie')
      r = s3_encryptor_obj.put_object(@selfie_url, bucket, @selfie_file)
      return r unless r.success?
      success
    end

    def s3_encryptor_obj
      @s3_encryptor_obj ||= Aws::S3Encryption.new(@kyc_salt_d, 'user')
    end

    def bucket
      GlobalConstant::Aws::Common.kyc_bucket
    end

    def get_file_path(file_type)
      file_name = Digest::MD5.hexdigest("#{Time.now.to_i}-#{file_type}-#{@user.id}-#{@user_secret.id}-#{@user.password}")
      "kyc/i/#{file_name}"
    end

  end

end
