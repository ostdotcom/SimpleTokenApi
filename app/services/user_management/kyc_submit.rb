module UserManagement

  class KycSubmit < ServicesBase

    S3_DOCUMENT_PATH_REGEX = GlobalConstant::UserKycDetail.s3_document_path_regex

    # Initialize
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # @params [Integer] client_id (mandatory) - client id
    # @params [Integer] user_id (mandatory) - user id
    # @params [Integer] client_id (mandatory) - client id
    # @params [String] first_name (mandatory) - first name
    # @params [String] last_name (mandatory) - last name
    # @params [String] birthdate (mandatory) - birth date
    # @params [String] country (mandatory) - country
    # @params [String] ethereum_address (optional) - ethereum address
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
      @ethereum_address = @params[:ethereum_address] # regex
      @document_id_number = @params[:document_id_number] # required
      @nationality = @params[:nationality] # required and one of allowed
      @document_id_file_path = @params[:document_id_file_path] # S3 Path of document_id File
      @selfie_file_path = @params[:selfie_file_path] # # S3 Path of Selfie File
      @residence_proof_file_path = @params[:residence_proof_file_path] # # S3 Path of residence_proof_file File
      @estimated_participation_amount = @params[:estimated_participation_amount]
      @investor_proof_files_path = @params[:investor_proof_files_path] # # S3 Path of Investor proofs File
      @uploaded_files = {}

      @client = nil
      @client_token_sale_details = nil
      @client_kyc_config_detail = nil
      @user = nil
      @kyc_salt_d = nil
      @kyc_salt_e = nil
      @user_kyc_detail = nil
      @user_extended_detail = nil

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

      r = validate_user_state
      return r unless r.success?

      r = generate_new_kyc_salt
      return r unless r.success?
      Rails.logger.info('---- generate_new_kyc_salt done')

      r = create_user_extended_details
      return r unless r.success?
      Rails.logger.info('---- create_user_extended_details done')

      r = init_or_update_user_kyc_detail
      return r unless r.success?

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

      @client_kyc_config_detail = ClientKycConfigDetail.get_from_memcache(@client_id)

      return error_with_data(
          'um_ks_5',
          'Invalid Request',
          'Invalid Request',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client_kyc_config_detail.blank?

      # Sanitize fields, validate and assign error
      validate_first_name
      validate_last_name
      validate_birthdate

      validate_ethereum_address
      validate_document_id_number
      validate_nationality
      validate_document_id_file_path
      validate_selfie_file_path

      validate_country
      validate_estimated_participation_amount
      validate_street_address
      validate_city
      validate_state
      validate_postal_code
      validate_residence_proof_file_path
      validate_investor_documents

      validate_uploaded_files

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
      @user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)

      if @user_kyc_detail.present?
        return unauthorized_access_response('um_ks_2') if @user_kyc_detail.client_id != @client_id

        return error_with_data(
            'um_ks_3',
            'Your KYC is already approved/denied.',
            'Your KYC is already approved/denied.',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if (@user_kyc_detail.kyc_approved? || @user_kyc_detail.kyc_denied?)

      end
      success
    end

    # validate user
    #
    # * Author: Aman
    # * Date: 02/05/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_user_state
      return error_with_data(
          'um_ks_p_vus_1',
          'Invalid user state for kyc submit ',
          'Double opt in not done by user',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @user.get_token_sale_state_page_name == GlobalConstant::User.get_token_sale_state_page_names("verification_page")

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
        if @birthdate.match(/\d{1,2}\/\d{1,2}\/\d{4,4}\z/)
          # if year is %y format then date changes to LMT zone (2 digit dates have issue)
          @birthdate = Time.zone.strptime(@birthdate, "%d/%m/%Y")

          age = (Time.zone.now.end_of_day - @birthdate)
          @error_data[:birthdate] = 'Min Age required is 18 years' if age < 18.year
          # Aml does not accept date less than 01/01/1900
          @error_data[:birthdate] = 'Enter date on or after 01/01/1900' if @birthdate.year < 1900

          @birthdate = @birthdate.to_date.to_s
        else
          @error_data[:birthdate] = "Invalid Birth Date Format.Valid Format(dd/mm/yyyy)"
        end
      rescue ArgumentError
        @error_data[:birthdate] = 'Invalid Birth Date.'
      end
    end

    def validate_street_address
      if !@client_kyc_config_detail.kyc_fields_array.include?(GlobalConstant::ClientKycConfigDetail.street_address_kyc_field)
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
      blacklisted_countries = @client_kyc_config_detail.blacklisted_countries
      @country = @country.to_s.strip.upcase
      if !@country.present? || !GlobalConstant::CountryNationality.countries.include?(@country)
        @error_data[:country] = 'Country is required.'
      elsif blacklisted_countries.include?(@country)
        @error_data[:country] = 'This Country is blacklisted by client'
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
      if !@client_kyc_config_detail.kyc_fields_array.include?(GlobalConstant::ClientKycConfigDetail.ethereum_address_kyc_field)
        @ethereum_address = nil
        return
      end

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
        @estimated_participation_amount = @estimated_participation_amount.to_f
        @error_data[:estimated_participation_amount] = 'Estimated participation amount should be greater than 0' if @estimated_participation_amount < 0.01
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
        return @error_data[:document_id_file_path] = 'Invalid S3 path for Identification document image' if !s3_kyc_folder_belongs_to_client?(@document_id_file_path)
        @uploaded_files[:document_id_file_path] = [@document_id_file_path]
      end
    end

    def validate_selfie_file_path
      @selfie_file_path = @selfie_file_path.to_s.strip
      if !@selfie_file_path.present?
        @error_data[:selfie_file_path] = 'Selfie is required.'
      else
        return @error_data[:selfie_file_path] = 'Invalid S3 path for Selfie' if !s3_kyc_folder_belongs_to_client?(@selfie_file_path)
        @uploaded_files[:selfie_file_path] = [@selfie_file_path]
      end
    end

    def validate_residence_proof_file_path
      @residence_proof_file_path = @residence_proof_file_path.to_s.strip
      if @client_kyc_config_detail.residency_proof_nationalities.include?(@nationality) && !@residence_proof_file_path.present?
        @error_data[:residence_proof_file_path] = 'Residence proof is required.'
      end

      if @residence_proof_file_path.present?
        return @error_data[:residence_proof_file_path] = 'Invalid S3 path for residence proof file' if !s3_kyc_folder_belongs_to_client?(@residence_proof_file_path)
        @uploaded_files[:residence_proof_file_path] = [@residence_proof_file_path]
      end

    end

    # Validate Investor documents files
    #
    # * Author: Pankaj
    # * Date: 26/04/2018
    # * Reviewed By:
    #
    #
    def validate_investor_documents
      return if @investor_proof_files_path.blank?

      # Investor proofs are not allowed for any client
      if !@client_kyc_config_detail.kyc_fields_array.include?(GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field)
        @investor_proof_files_path = nil
        return
      end

      # Investor proof files path has to be an array
      if !@investor_proof_files_path.is_a?(Array)
        @error_data[:investor_proof_files_path] = 'Investor proof files path has to be an array.'
        return
      end

      if @investor_proof_files_path.length > GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed
        @error_data[:investor_proof_files_path] = "Max #{GlobalConstant::ClientKycConfigDetail.number_of_investor_proofs_allowed} documents are allowed as investor proof."
      end

      # If any of the file does not matches s3 file path
      @uploaded_files[:investor_proof_files_path] = []
      @investor_proof_files_path.each do |x|
        if !s3_kyc_folder_belongs_to_client?(x)
          @error_data[:investor_proof_files_path] = 'Invalid S3 path for investor proof file'
          next
        end
        @uploaded_files[:investor_proof_files_path] << x
      end
    end

    # Validate all uploaded files exists on s3 and falls in content length range or not
    #
    # * Author: Pankaj
    # * Date: 28/08/2018
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def validate_uploaded_files
      threads = []
      s3_manager = Aws::S3Manager.new('kyc', 'admin')
      s3_bucket = s3_manager.get_s3_bucket_object(GlobalConstant::Aws::Common.kyc_bucket)
      @uploaded_files.each do |key, s3_files|
        s3_files.each do |s3_file_path|
          threads << Thread.new(key, s3_file_path) do |k, v|
            Rails.logger.info "#{k} => File verification starts at #{Time.now.to_f}"
            file_size = s3_bucket.object(v).data.content_length rescue 0
            if file_size.zero?
              @error_data[k] = "File is not present on S3"
            elsif file_size < s3_manager.min_file_size
              @error_data[k] = "Minimum file size should be 200kB"
            elsif file_size > s3_manager.max_file_size
              @error_data[k] = "Max file size should be 20MB"
            end

            Rails.logger.info "#{k} => File verified at #{Time.now.to_f}"
          end
        end
      end
      threads.each {|t| t.join}
    end

    # S3 Kyc Folder belongs to the client
    #
    # * Author: Aman
    # * Date: 23/07/2018
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def s3_kyc_folder_belongs_to_client?(file_path)
      file_path.starts_with?("#{@client_id}/") && (!(file_path =~ S3_DOCUMENT_PATH_REGEX).nil?)
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
    # sets @user_extended_detail
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
          residence_proof_file_path: @residence_proof_file_path,
          investor_proof_files_path: @investor_proof_files_path
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
        next if value.blank?
        md5_user_extended_details_params[key.to_sym] = Md5UserExtendedDetail.get_hashed_value(value)
      end

      @user_extended_detail = UserExtendedDetail.create!(user_extended_details_params)

      md5_user_extended_details_params.merge!(user_extended_detail_id: @user_extended_detail.id)

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
    def init_or_update_user_kyc_detail

      Rails.logger.info('-- find_or_init_user_kyc_detail')

      # Update records
      if @user_kyc_detail.blank?
        @user_kyc_detail = UserKycDetail.new(user_id: @user_id)
        @user_kyc_detail.client_id = @user.client_id
        @user_kyc_detail.token_sale_participation_phase = GlobalConstant::TokenSale.early_access_token_sale_phase
        @user_kyc_detail.email_duplicate_status = GlobalConstant::UserKycDetail.no_email_duplicate_status
        @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status
        @user_kyc_detail.submission_count = 0
      end
      @user_kyc_detail.qualify_types = 0
      @user_kyc_detail.admin_action_types = 0
      @user_kyc_detail.user_extended_detail_id = @user_extended_detail.id
      @user_kyc_detail.submission_count += 1
      @user_kyc_detail.kyc_duplicate_status = GlobalConstant::UserKycDetail.unprocessed_kyc_duplicate_status
      @user_kyc_detail.aml_status = GlobalConstant::UserKycDetail.unprocessed_aml_status
      @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.unprocessed_admin_status
      @user_kyc_detail.last_reopened_at = nil
      @user_kyc_detail.save!

      success
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
      # @user.send("set_" + GlobalConstant::User.token_sale_double_optin_mail_sent_property)
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
              user_extended_detail_id: @user_extended_detail.id,
              action: GlobalConstant::UserActivityLog.update_kyc_action,
              action_timestamp: Time.now.to_i
          }
      )
      Rails.logger.info('---- enqueue_job KycSubmitJob done')

    end

  end

end
