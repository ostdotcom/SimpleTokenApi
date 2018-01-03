module AdminManagement

  module Kyc

    module Dashboard

      class ContractEvents < ServicesBase

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 09/11/2017
        # * Reviewed By: Sunil
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Integer] page_size (optional)
        # @params [Integer] offset (optional)
        #
        # @return [AdminManagement::Kyc::Dashboard::SaleDaily]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @client_id = @params[:client_id]
          @page_size = @params[:page_size]
          @offset = @params[:offset]

          @curr_page_data = []
          @all_time_data = {}
        end

        # perform
        #
        # * Author: Alpesh
        # * Date: 09/11/2017
        # * Reviewed By: Sunil
        #
        # @return [Result::Base]
        #
        def perform

          r = validate_and_sanitize
          return r unless r.success?

          r = validate_for_contract_events_access
          return r unless r.success?

          fetch_contract_events_data

          set_api_response_data

          success_with_data(@api_response_data)
        end

        private

        # Validate and sanitize
        #
        # * Author: Alpesh
        # * Date: 09/11/2017
        # * Reviewed By: Sunil
        #
        # return [Result::Base]
        #
        def validate_and_sanitize
          r = validate
          return r unless r.success?

          @page_size = 100 if @page_size.to_i < 1 || @page_size.to_i > 100
          @offset = 0 if @offset.to_i <= 0

          r = fetch_and_validate_client
          return r unless r.success?

          success
        end

        # fetch client and validate
        #
        # * Author: Aman
        # * Date: 26/12/2017
        # * Reviewed By:
        #
        # Sets @client
        #
        # @return [Result::Base]
        #
        def fetch_and_validate_client
          @client = Client.get_from_memcache(@client_id)

          return error_with_data(
              'am_k_d_ce_1',
              'Client is not active',
              'Client is not active',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @client.status != GlobalConstant::Client.active_status

          success
        end

        # check if client has access for contract events read
        #
        # * Author: Aman
        # * Date: 26/12/2017
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def validate_for_contract_events_access

          return error_with_data(
              'am_k_d_ce_2',
              'Client does not access for events dashboard',
              'Client does not access for events dashboard',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @client.id != GlobalConstant::TokenSale.st_token_sale_client_id

          success
        end

        # Set API response data
        #
        # * Author: Alpesh
        # * Date: 09/11/2017
        # * Reviewed By: Sunil
        #
        # Sets @curr_page_data
        #
        def fetch_contract_events_data

          @total_filtered_recs = ContractEvent.count

          ContractEvent.order("block_number DESC").each do |c_e|

            @curr_page_data << {
                block_number: c_e.block_number,
                event_name: c_e.kind,
                contract_address: c_e.contract_address,
                processed_event_data: c_e.processed_event_data
            }

          end

        end

        # Set API response data
        #
        # * Author: Alpesh
        # * Date: 09/11/2017
        # * Reviewed By: Sunil
        #
        # Sets @api_response_data
        #
        def set_api_response_data

          @api_response_data = {
              meta: {
                  page_offset: @offset,
                  page_size: @page_size,
                  total_filtered_recs: @total_filtered_recs
              },
              curr_page_data: @curr_page_data
          }

        end

      end

    end

  end

end
