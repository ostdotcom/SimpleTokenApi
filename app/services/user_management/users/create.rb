module UserManagement
  module Users
    class Create < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @param [String] client_id (mandatory) -  client id of user
      # @param [String] email (mandatory) - email of user
      #
      # @return [UserManagement::Users::Create]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @email = @params[:email]

        @new_user_added = false
        @user = nil
      end


      # Perform
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        find_or_initialize_user

        enqueue_job if @new_user_added

        success_with_data(@user)

      end

      private

      # Validate and sanitize
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      # Sets @parsed_request_time, @url_path, @request_parameters
      #
      def validate_and_sanitize

        r = validate
        return r unless r.success?

        return error_with_data(
            'sm_au_1',
            'Please enter a valid email address',
            'Please enter a valid email address',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) unless Util::CommonValidator.is_valid_email?(@email)

        r = fetch_and_validate_client
        return r unless r.success?

        r = validate_if_st_default_client
        return r unless r.success?

        success
      end

      # Fetch and Validate client
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_if_st_default_client
        return error_with_data(
            'sm_au_2',
            'unauthorized client action',
            'unauthorized client action',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @client.is_st_token_sale_client?

        success
      end

      # find or initialize user
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # Sets @user
      #
      def find_or_initialize_user
        @user = User.find_or_initialize_by(client_id: @client_id, email: @email)
        @new_user_added = true if @user.new_record?
        @user.save! if @user.changed?
      end

      # Do remaining task in sidekiq
      #
      # * Author: Aman
      # * Date: 22/01/2018
      # * Reviewed By:
      #
      def enqueue_job
        if @user_ip_address.present?
          @geoip_country = GlobalConstant::CountryNationality.get_maxmind_country_from_ip(ip_address: @user_ip_address).to_s.downcase
        end

        BgJob.enqueue(
            NewUserRegisterJob,
            {
                user_id: @user.id,
                ip_address: @user_ip_address,
                geoip_country: @geoip_country
            }
        )
      end
    end

  end
end