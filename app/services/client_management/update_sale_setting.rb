module ClientManagement
  class UpdateSaleSetting < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [Integer] client_id (mandatory) -  client id
    # @param [String] sale_start_timestamp (mandatory) - sale_start_timestamp (timestamp)
    # @param [String] sale_end_timestamp (mandatory) - sale_end_timestamp (timestamp)
    #
    # @return [ClientManagement::UpdateSaleSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @sale_start_timestamp = @params[:sale_start_timestamp]
      @sale_end_timestamp = @params[:sale_end_timestamp]

      @client_token_sale_detail = nil

    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      update_sale_setting

      success_with_data(success_response_data)
    end


    # private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      r = validate_date
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @admin, @client
    #
    def validate_client_and_admin
      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Validate Date
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @sale_start_timestamp, @sale_end_timestamp
    # @return [Result::Base]
    #
    def validate_date

      return error_with_data(
          'cm_uss_vd_1',
          'Invalid Date in the field from and to',
          'Invalid Date',
          GlobalConstant::ErrorAction.default,
          {}
      ) if (@sale_end_timestamp <= @sale_start_timestamp)

      return error_with_data(
          'cm_uss_vd_2',
          'The to date cannot be less that today date',
          'Invalid Date in the field to',
          GlobalConstant::ErrorAction.default,
          {}
      ) if (@sale_end_timestamp <= Time.zone.now.to_i)

      success
    end

    # Update Sale Setting
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @Client_token_sale_detail
    #
    def update_sale_setting
      @Client_token_sale_detail = ClientTokenSaleDetail.where(client_id: @client_id).
          update(sale_start_timestamp: @sale_start_timestamp, sale_end_timestamp: @sale_end_timestamp)
    end

    # Api response data
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {

      }
    end

  end
end
