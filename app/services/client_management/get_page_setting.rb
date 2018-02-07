module ClientManagement

  class GetPageSetting < ServicesBase


    # Initialize
    #
    # * Author: Aman
    # * Date: 08/02/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [String] template_type (mandatory) -  page_name
    #
    # @return [ClientManagement::GetPageSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @template_type = @params[:template_type]

      @client = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 08/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      success
    end

  end
end