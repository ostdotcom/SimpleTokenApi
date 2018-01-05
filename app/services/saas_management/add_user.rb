module SaasManagement
  class AddUser < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] client_id (mandatory) -  api key of client
    # @param [String] email (mandatory) - generated signature
    #
    # @return [SaasManagement::AddUser]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @email = @params[:email]
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
      @user.save! if @user.changed?
    end

  end
end