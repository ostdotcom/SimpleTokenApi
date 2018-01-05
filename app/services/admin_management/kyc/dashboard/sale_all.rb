module AdminManagement

  module Kyc

    module Dashboard

      class SaleAll < ServicesBase

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
        # @return [AdminManagement::Kyc::Dashboard::Sale]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @client_id = @params[:client_id]
          @page_size = @params[:page_size]
          @offset = @params[:offset]

          @total_filtered_kycs = 0
          @curr_page_data = []
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

          r = validate_for_sale_dashboard_access
          return r unless r.success?

          fetch_purchase_data

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

          @page_size = 50 if @page_size.to_i < 1 || @page_size.to_i > 50
          @offset = 0 if @offset.to_i <= 0

          r = fetch_and_validate_client
          return r unless r.success?

          success
        end

        # check if client has access for sale dashboard
        #
        # * Author: Aman
        # * Date: 26/12/2017
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def validate_for_sale_dashboard_access

          return error_with_data(
              'am_k_d_sa_2',
              'Client does not access for sale dashboard',
              'Client does not access for sale dashboard',
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
        # Sets @total_filtered_kycs, @curr_page_data
        #
        def fetch_purchase_data

          @total_filtered_kycs = PurchaseLog.count

          PurchaseLog
              .limit(@page_size).offset(@offset)
              .order("block_creation_timestamp DESC")
              .each do |p_l|

            @curr_page_data << {
                day_timestamp: Time.at(p_l.block_creation_timestamp).in_time_zone('UTC').strftime("%d/%m/%Y %H:%M"),
                ethereum_address: "#{p_l.ethereum_address[0, 7]}...",
                ethereum_value: GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(p_l.ether_wei_value),
                tokens_sold: GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(p_l.st_wei_value),
                usd_value: p_l.usd_value.to_f.round(2)
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
                  total_filtered_recs: @total_filtered_kycs
              },
              curr_page_data: @curr_page_data
          }

        end

      end

    end

  end

end
