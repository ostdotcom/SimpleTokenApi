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
        # @params [Integer] page_size (optional)
        # @params [Integer] offset (optional)
        #
        # @return [AdminManagement::Kyc::Dashboard::Sale]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
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
              .order("pst_day_start_timestamp DESC")
              .each do |p_l|

            @curr_page_data << {
                day_timestamp: Time.at(p_l.created_at).strftime("%d/%m/%Y %H:%M"),
                ethereum_address: p_l.ethereum_address,
                ethereum_value: GlobalConstant::ConversionRate.wei_to_basic_unit(p_l.ether_wei_value),
                tokens_sold: GlobalConstant::ConversionRate.wei_to_basic_unit(p_l.st_wei_value),
                usd_value: p_l.usd_value
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
                  total_filtered_recs: @total_filtered_kycs.length
              },
              curr_page_data: @curr_page_data
          }

        end

      end

    end

  end

end
