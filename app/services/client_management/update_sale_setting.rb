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
      begin
        @sale_start_timestamp = @sale_start_timestamp.to_s.strip
        @sale_end_timestamp = @sale_end_timestamp.to_s.strip
        if @sale_start_timestamp.match(/\d{1,2}\/\d{1,2}\/\d{4,4}\z/) && @sale_end_timestamp.match(/\d{1,2}\/\d{1,2}\/\d{4,4}\z/)
          # if year is %y format then date changes to LMT zone (2 digit dates have issue)
          @sale_start_timestamp = Time.zone.strptime(@sale_start_timestamp, "%d/%m/%Y")
          @sale_end_timestamp = Time.zone.strptime(@sale_end_timestamp, "%d/%m/%Y")

          puts "@sale_start_timestamp : #{@sale_start_timestamp}"
          puts "@sale_end_timestamp : #{@sale_end_timestamp}"

          time_diff = (@sale_end_timestamp - @sale_start_timestamp)
          validate_to = (@sale_end_timestamp - Time.zone.now)

          puts "time_diff : #{time_diff}"
          puts "validate_to : #{validate_to}"

          return error_with_data(
              'cm_uss_vd_1',
              'Invalid Date in the field from and to',
              'Invalid Date',
              GlobalConstant::ErrorAction.default,
              {}
          ) if (time_diff <= 0)

          return error_with_data(
              'cm_uss_vd_2',
              'The to date cannot be less that today date',
              'Invalid Date in the field to',
              GlobalConstant::ErrorAction.default,
              {}
          ) if (validate_to <= 0)

          @sale_start_timestamp = @sale_start_timestamp.to_date.to_time.to_i
          @sale_end_timestamp = @sale_end_timestamp.to_date.to_time.to_i
        else
          return error_with_data(
              'cm_uss_vd_3',
              'Invalid Date Format.Valid Format(dd/mm/yyyy)',
              'Invalid Date',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end
      rescue ArgumentError
        return error_with_data(
            'cm_uss_vd_4',
            'Invalid Date',
            'Invalid Date',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end
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
      @Client_token_sale_detail = ClientTokenSaleDetail.where(client_id: @client_id).update(sale_start_timestamp: @sale_start_timestamp, sale_end_timestamp: @sale_end_timestamp)
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
