module SaasManagement
  class AddUser < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [AR] client (mandatory) - client obj
    # @param [String] email (mandatory) - generated signature
    # @param [String] user_ip_address (optional ) - user ip address
    #
    #
    # @return [SaasManagement::AddUser]
    #
    def initialize(params)
      super

      @client = @params[:client]
      @email = @params[:email]
      @user_ip_address = @params[:user_ip_address]

      @client_id = @client.id

      @geoip_country = nil
      @new_user_added = false
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

      success_with_data(user_id: @user.id)

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
      ) unless Util::CommonValidateAndSanitize.is_valid_email?(@email)

      fetch_client_token_sale_details

      r = validate_client_details
      return r unless r.success?

      success
    end

    # Fetch token sale details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_token_sale_details
      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)
    end

    # Validate client
    #
    # * Author: Aman
    # * Date: 02/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_client_details
      return error_with_data(
          'sm_au_2',
          'unauthorized client action',
          'unauthorized client action',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client.is_st_token_sale_client? || @client.is_web_host_setup_done?

      return error_with_data(
          'sm_au_3',
          'Registration has ended, it is no longer possible to add user now',
          'Registration has ended, it is no longer possible to add user now',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client_token_sale_details.has_registration_ended?

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
      @user = User.using_client_shard(client: @client).find_or_initialize_by(client_id: @client_id, email: @email)
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
              client_id: @client_id,
              user_id: @user.id,
              geoip_country: @geoip_country,
              event: {
                  client_id: @user.client_id,
                  event_source: GlobalConstant::Event.api_source,
                  event_name: GlobalConstant::Event.user_register_name,
                  event_data: {
                      user: @user.get_hash
                  },
                  event_timestamp: Time.now.to_i
              }
          }
      )
    end

  end
end