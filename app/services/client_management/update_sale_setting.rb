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
    # @param [Integer] sale_start_timestamp (mandatory) - sale_start_timestamp (timestamp)
    # @param [Integer] sale_end_timestamp (mandatory) - sale_end_timestamp (timestamp)
    #
    # @param [Integer] has_registration_setting (optional) - has_registration_setting (0/1)
    # @param [Integer] registration_end_timestamp (optional) -  registration_end_timestamp (timestamp)
    #
    # @return [ClientManagement::UpdateSaleSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @sale_start_timestamp = @params[:sale_start_timestamp].to_i
      @sale_end_timestamp = @params[:sale_end_timestamp].to_i

      @has_registration_setting = @params[:has_registration_setting].to_i
      @registration_end_timestamp = @params[:registration_end_timestamp].to_i

      @sale_start_timestamp = (@sale_start_timestamp/1000).to_i
      @registration_end_timestamp = (@registration_end_timestamp/1000).to_i
      @sale_end_timestamp = (@sale_end_timestamp/1000).to_i
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

      @registration_end_timestamp = nil if @has_registration_setting != 1

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
      err_data = {}

      err_data[:sale_start_timestamp] = 'Invalid date selected' if @sale_start_timestamp < 0
      err_data[:sale_end_timestamp] = 'Invalid date selected' if @sale_end_timestamp < 0
      err_data[:registration_end_timestamp] = 'Invalid date selected' if @registration_end_timestamp < 0

      err_data[:sale_end_timestamp] = 'End date cannot be more than 5 years from now' if @sale_end_timestamp >
          (Time.now.to_i + 5.years.to_i)

      return error_with_data(
          'cm_uss_vd_1',
          'Invalid Date',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          err_data
      ) if err_data.present?

      return error_with_data(
          'cm_uss_vd_2',
          'Sale start should be less than sale end time',
          'Sale start time should be less than sale end time',
          GlobalConstant::ErrorAction.default,
          {}
      ) if (@sale_end_timestamp <= @sale_start_timestamp)

      return error_with_data(
          'cm_uss_vd_3',
          'Registration end time should not be greater than sale end time',
          'Registration end time should not be greater than sale end time',
          GlobalConstant::ErrorAction.default,
          {}
      ) if (@registration_end_timestamp > @sale_end_timestamp)

      success
    end

    # Update Sale Setting
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @client_token_sale_detail
    #
    def update_sale_setting
      @client_token_sale_detail = ClientTokenSaleDetail.get_from_memcache(@client_id)

      @client_token_sale_detail.sale_start_timestamp =  @sale_start_timestamp
      @client_token_sale_detail.registration_end_timestamp =  @registration_end_timestamp
      @client_token_sale_detail.sale_end_timestamp = @sale_end_timestamp
      @client_token_sale_detail.save! if @client_token_sale_detail.changed?
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
      {}
    end

  end
end
