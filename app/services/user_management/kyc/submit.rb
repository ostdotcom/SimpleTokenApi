module UserManagement
  module Kyc
    class Submit < ServicesBase

      S3_DOCUMENT_PATH_REGEX = GlobalConstant::UserKycDetail.s3_document_path_regex
      MAX_ALLOWED_LENGTH = 100
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
      # @params [String] nationality (mandatory) - document_id country
      # @params [String] document_id_number (mandatory) - document_id number
      # @params [String] document_id_file_path (mandatory) - document_id file
      # @params [String] selfie_file_path (mandatory) - selfie file
      # @params [String] residence_proof_file_path (optional) - residency proof
      # @params [String] investor_proof_files_path (optional) - investor proof
      # @params [String] ethereum_address (optional) - ethereum address
      # @params [String] estimated_participation_amount (optional) - estimated participation amount
      # @params [String] street_address (optional) - street address
      # @params [String] city (optional) - city
      # @params [String] state (optional) - state
      # @params [String] postal_code (optional) - postal code
      #
      # Sets client, client_token_sale_details, client_kyc_config_detail, user, kyc_salt_d, kyc_salt_e,
      # user_kyc_detail, user_extended_detail, param_error_identifiers
      #
      # @return [UserManagement::Kyc::Submit]
      #
      def initialize(params)
        # super
        @params = params

        @user_id = @params[:user_id]
        @client_id = @params[:client_id]
        @first_name = @params[:first_name] # required
        @last_name = @params[:last_name] # required
        @birthdate = @params[:birthdate] # format - 'dd/mm/yyyy'
        @country = @params[:country] # required and one of allowed
        @nationality = @params[:nationality] # required and one of allowed
        @document_id_number = @params[:document_id_number] # required
        @document_id_file_path = @params[:document_id_file_path] # S3 Path of document_id File
        @selfie_file_path = @params[:selfie_file_path] # # S3 Path of Selfie File
        @residence_proof_file_path = @params[:residence_proof_file_path] # # S3 Path of residence_proof_file File
        @investor_proof_files_path = @params[:investor_proof_files_path] # # S3 Path of Investor proofs File
        @ethereum_address = @params[:ethereum_address] # regex
        @estimated_participation_amount = @params[:estimated_participation_amount]
        @street_address = @params[:street_address]
        @city = @params[:city]
        @state = @params[:state]
        @postal_code = @params[:postal_code]

        @uploaded_files = {}
        @extra_kyc_fields = {}

        @source_of_request = @params[:source_of_request]
        @client = nil
        @client_token_sale_details = nil
        @client_kyc_config_detail = nil
        @user = nil
        @kyc_salt_d = nil
        @kyc_salt_e = nil
        @user_kyc_detail = nil
        @user_extended_detail = nil

        @param_error_identifiers = []
        @params_error_data = {}
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

        fetch_admin
        enqueue_job

        # success_with_data({user_id: @user_id})
        success_with_data(service_response_data)
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
        # NOTE: To be on safe side, check for generic errors as well
        # r = validate
        # return r unless r.success?

        @client_kyc_config_detail = ClientKycConfigDetail.get_from_memcache(@client_id)

        # Sanitize fields, validate and assign error
        r = validate_and_sanitize_params
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)

        return error_with_identifier('token_sale_ended',
                                     'um_ks_vs_2'
        ) if @client_token_sale_details.has_token_sale_ended?

        # Check if user KYC is already approved
        @user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)

        if @user_kyc_detail.present?
          # resource not found
          return error_with_identifier('resource_not_found',
                                       'um_ks_vs_3'
          ) if @user_kyc_detail.client_id != @client_id ||
              (@user_kyc_detail.status != GlobalConstant::UserKycDetail.active_status)

          return error_with_identifier('case_closed',
                                       'um_ks_vs_4'
          ) if (@user_kyc_detail.kyc_approved? || @user_kyc_detail.kyc_denied?)
        end
        success
      end

      def validate_and_sanitize_params
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
        validate_extra_kyc_fields

        @param_error_identifiers.uniq!
        return error_with_identifier('invalid_api_params',
                                     'um_ks_vasp_1',
                                     @param_error_identifiers,
                                     'There were some errors in your KYC. Please correct and resubmit',
                                     @params_error_data
        ) if @param_error_identifiers.any? || @params_error_data.present?

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
        return error_with_identifier('double_opt_in_error',
                                     'um_ks_p_vus_1',
                                     []
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
        @param_error_identifiers << "missing_first_name" and return if @first_name.to_s.strip.blank?
        @param_error_identifiers << 'invalid_first_name' unless Util::CommonValidateAndSanitize.is_string?(@first_name)
        @first_name = @first_name.to_s.strip
        @param_error_identifiers << 'invalid_first_name' if @first_name.length > MAX_ALLOWED_LENGTH
      end

      def validate_last_name
        @param_error_identifiers << "missing_last_name" and return if @last_name.to_s.strip.blank?
        @param_error_identifiers << 'invalid_last_name' unless Util::CommonValidateAndSanitize.is_string?(@last_name)
        @last_name = @last_name.to_s.strip
        @param_error_identifiers << 'invalid_last_name' if @last_name.length > MAX_ALLOWED_LENGTH
      end

      def validate_birthdate
        begin
          @birthdate = @birthdate.to_s.strip
          @param_error_identifiers << "missing_birthdate" and return if @birthdate.blank?

          if @birthdate.match(/\d{1,2}\/\d{1,2}\/\d{4,4}\z/)
            # if year is %y format then date changes to LMT zone (2 digit dates have issue)
            @birthdate = Time.zone.strptime(@birthdate, "%d/%m/%Y")

            age = (Time.zone.now.end_of_day - @birthdate)
            @param_error_identifiers << 'invalid_birthdate_age' if age < 18.year || age > 100.year

            @birthdate = @birthdate.to_date.to_s
          else
            @param_error_identifiers << 'invalid_birthdate'
          end
        rescue ArgumentError
          @param_error_identifiers << 'invalid_birthdate'
        end
      end

      def validate_street_address
        if @client_kyc_config_detail.kyc_fields_array.exclude?(GlobalConstant::ClientKycConfigDetail.street_address_kyc_field)
          @street_address = nil
          return
        end
        @param_error_identifiers << "missing_street_address" and return if @street_address.to_s.strip.blank?
        @param_error_identifiers << 'invalid_street_address' unless Util::CommonValidateAndSanitize.is_string?(@street_address)

        @street_address = @street_address.to_s.strip
      end

      def validate_city
        if @client_kyc_config_detail.kyc_fields_array.exclude?(GlobalConstant::ClientKycConfigDetail.city_kyc_field)
          @city = nil
          return
        end
        @param_error_identifiers << "missing_city" and return if @city.to_s.strip.blank?
        @param_error_identifiers << 'invalid_city' unless Util::CommonValidateAndSanitize.is_string?(@city)

        @city = @city.to_s.strip
      end

      def validate_country
        @param_error_identifiers << "missing_country" and return if @country.to_s.strip.blank?
        @param_error_identifiers << 'invalid_country' and return unless Util::CommonValidateAndSanitize.is_string?(@country)

        blacklisted_countries = @client_kyc_config_detail.blacklisted_countries
        @country = @country.to_s.strip.upcase
        if !GlobalConstant::CountryNationality.countries.include?(@country)
          @param_error_identifiers << 'invalid_country'
        elsif blacklisted_countries.include?(@country)
          @param_error_identifiers << 'blacklisted_country'
        end
      end

      def validate_state
        if @client_kyc_config_detail.kyc_fields_array.exclude?(GlobalConstant::ClientKycConfigDetail.state_kyc_field)
          @state = nil
          return
        end
        @param_error_identifiers << "missing_state" and return if @state.to_s.strip.blank?
        @param_error_identifiers << 'invalid_state' unless Util::CommonValidateAndSanitize.is_string?(@state)

        @state = @state.to_s.strip
      end

      def validate_postal_code
        if @client_kyc_config_detail.kyc_fields_array.exclude?(GlobalConstant::ClientKycConfigDetail.postal_code_kyc_field)
          @postal_code = nil
          return
        end
        @param_error_identifiers << "missing_postal_code" and return if @postal_code.to_s.strip.blank?
        @param_error_identifiers << 'invalid_postal_code' unless Util::CommonValidateAndSanitize.is_string?(@postal_code)

        @postal_code = @postal_code.to_s.strip
      end

      def validate_ethereum_address
        if @client_kyc_config_detail.kyc_fields_array.exclude?(GlobalConstant::ClientKycConfigDetail.ethereum_address_kyc_field)
          @ethereum_address = nil
          return
        end
        @param_error_identifiers << "missing_ethereum_address" and return if @ethereum_address.to_s.strip.blank?
        @ethereum_address = Util::CommonValidator.sanitize_ethereum_address(@ethereum_address)
        unless Util::CommonValidator.is_ethereum_address?(@ethereum_address)
          @param_error_identifiers << 'invalid_ethereum_address'
        end
      end

      def validate_estimated_participation_amount
        if @client_kyc_config_detail.kyc_fields_array.exclude?(GlobalConstant::ClientKycConfigDetail.estimated_participation_amount_kyc_field)
          @estimated_participation_amount = nil
          return
        end
        @param_error_identifiers << "missing_estimated_participation_amount" and return if @estimated_participation_amount.to_s.strip.blank?
        if Util::CommonValidateAndSanitize.is_float?(@estimated_participation_amount)
          @estimated_participation_amount = @estimated_participation_amount.to_f
          @param_error_identifiers << 'invalid_estimated_participation_amount' if @estimated_participation_amount < 0.01
        else
          @param_error_identifiers << 'invalid_estimated_participation_amount'
        end
      end

      def validate_document_id_number
        @param_error_identifiers << "missing_document_id_number" and return if @document_id_number.to_s.strip.blank?
        @param_error_identifiers << 'invalid_document_id_number' unless Util::CommonValidateAndSanitize.is_string?(@document_id_number)
        @document_id_number = @document_id_number.to_s.strip.downcase
      end

      def validate_nationality
        @param_error_identifiers << "missing_nationality" and return if @nationality.to_s.strip.blank?
        @param_error_identifiers << 'invalid_nationality' and return unless Util::CommonValidateAndSanitize.is_string?(@nationality)

        @nationality = @nationality.to_s.strip.upcase
        if !GlobalConstant::CountryNationality.nationalities.include?(@nationality)
          @param_error_identifiers << 'invalid_nationality'
        end
      end

      def validate_document_id_file_path
        @param_error_identifiers << "missing_document_id_file_path" and return if @document_id_file_path.to_s.strip.blank?
        @param_error_identifiers << 'invalid_document_id_file_path' and return unless Util::CommonValidateAndSanitize.is_string?(@document_id_file_path)
        @document_id_file_path = @document_id_file_path.to_s.strip

        @param_error_identifiers << 'invalid_document_id_file_path' and return unless s3_kyc_folder_belongs_to_client?(@document_id_file_path)
        @uploaded_files[:document_id_file_path] = [@document_id_file_path]

      end

      def validate_selfie_file_path
        @param_error_identifiers << "missing_selfie_file_path" and return if @selfie_file_path.to_s.strip.blank?
        @param_error_identifiers << 'invalid_selfie_file_path' and return unless Util::CommonValidateAndSanitize.is_string?(@selfie_file_path)
        @selfie_file_path = @selfie_file_path.to_s.strip

        @param_error_identifiers << 'invalid_selfie_file_path' and return unless s3_kyc_folder_belongs_to_client?(@selfie_file_path)
        @uploaded_files[:selfie_file_path] = [@selfie_file_path]
      end

      def validate_residence_proof_file_path
        if @residence_proof_file_path.present? && !Util::CommonValidateAndSanitize.is_string?(@residence_proof_file_path)
          @param_error_identifiers << 'invalid_residence_proof_file_path'
          return
        end

        @residence_proof_file_path = @residence_proof_file_path.to_s.strip
        if @client_kyc_config_detail.residency_proof_nationalities.include?(@nationality) && !@residence_proof_file_path.present?
          @param_error_identifiers << 'missing_residence_proof_file_path'
        end

        if @residence_proof_file_path.present?
          return @param_error_identifiers << 'invalid_residence_proof_file_path' unless s3_kyc_folder_belongs_to_client?(@residence_proof_file_path)
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
        if @client_kyc_config_detail.kyc_fields_array.exclude?(GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field)
          @investor_proof_files_path = nil
          return
        end
        # Investor proof files path has to be an array
        @param_error_identifiers << 'invalid_investor_proof_files_path' and return unless Util::CommonValidateAndSanitize.is_array?(@investor_proof_files_path, 'string')


        if @investor_proof_files_path.length > GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed
          @param_error_identifiers << 'invalid_investor_proof_files_path_count'
        end

        # If any of the file does not matches s3 file path
        @uploaded_files[:investor_proof_files_path] = []
        @investor_proof_files_path.each do |x|
          unless s3_kyc_folder_belongs_to_client?(x)
            @param_error_identifiers << 'invalid_investor_proof_files_path'
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
                @param_error_identifiers << "file_not_found_#{k}"
              elsif file_size < s3_manager.min_file_size || file_size > s3_manager.max_file_size
                @param_error_identifiers << "wrong_file_size_of_#{k}"
              end

              Rails.logger.info "#{k} => File verified at #{Time.now.to_f}"
            end
          end
        end
        threads.each {|t| t.join}
      end

      def validate_extra_kyc_fields
        @client_kyc_config_detail.extra_kyc_fields.each do |key, config|
          val = @params[key.to_sym]

          if config[:data_type] == GlobalConstant::ClientKycConfigDetail.text_data_type
            val = val.to_s.strip
            next if config[:validation][:required] != 1 && val.blank?

            @params_error_data[key.to_sym] = "#{config[:label]} is mandatory" and next if val.blank?
            @params_error_data[key.to_sym] = "Please provide a valid #{config[:label]}" and next unless Util::CommonValidateAndSanitize.is_string?(val)
            @extra_kyc_fields[key.to_sym] = val
          end

        end
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

        return error_with_identifier('resource_not_found',
                                     'um_ks_4'
        ) unless @user.present? && @user.client_id == @client_id &&
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
            investor_proof_files_path: @investor_proof_files_path,
            extra_kyc_fields: @extra_kyc_fields
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
        @user.send("set_" + GlobalConstant::User.kyc_submitted_property)
        # @user.send("set_" + GlobalConstant::User.doptin_mail_sent_property)
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
        BgJob.enqueue(
            KycSubmitJob,
            {
                user_id: @user_id,
                user_extended_detail_id: @user_extended_detail.id,
                action: GlobalConstant::UserActivityLog.update_kyc_action,
                action_timestamp: Time.now.to_i,
                event: {
                    client_id: @user.client_id,
                    event_source: @source_of_request,
                    # event data is not passed as it is fetched inside the job. Aml status is updated in job
                    event_name: GlobalConstant::Event.kyc_submit_name,
                    event_timestamp: Time.now.to_i
                }
            }
        )
        Rails.logger.info('---- enqueue_job KycSubmitJob done')

      end

      # Fetch Admin
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets @admin
      #
      def fetch_admin
        if @user_kyc_detail.last_acted_by.to_i > 0
          @admin = Admin.get_from_memcache(@user_kyc_detail.last_acted_by)
        end
      end

      # Format service response
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def service_response_data
        {
            user_kyc_detail: @user_kyc_detail.get_hash,
            admin: @admin.present? ? @admin.get_hash : {}
        }
      end

    end
  end
end
