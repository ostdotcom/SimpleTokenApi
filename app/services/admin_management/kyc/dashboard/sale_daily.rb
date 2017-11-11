module AdminManagement

  module Kyc

    module Dashboard

      class SaleDaily < ServicesBase

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
        # @return [AdminManagement::Kyc::Dashboard::SaleDaily]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
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
        # Sets @curr_page_data
        #
        def fetch_purchase_data

          @all_time_data = { total_ethereum: 0, total_tokens_sold: 0, total_dollars_value: 0}

          total_ether_value_in_wei, total_st_value_in_wei = 0 , 0

          PurchaseLog
              .select("pst_day_start_timestamp, sum(ether_wei_value) as total_ether_value, sum(st_wei_value) as total_simple_token_value, sum(usd_value) as total_usd_value")
              .group("pst_day_start_timestamp")
              .order("pst_day_start_timestamp DESC")
              .each do |p_l|

            total_ethereum = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(p_l.total_ether_value)
            total_tokens_sold = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(p_l.total_simple_token_value)
            total_dollars_value = p_l.total_usd_value.to_f.round(2)

            @curr_page_data << {
                day_timestamp: Time.at(p_l.pst_day_start_timestamp).in_time_zone('Pacific Time (US & Canada)').strftime("%d/%m/%Y"),
                total_ethereum: total_ethereum,
                total_tokens_sold: total_tokens_sold,
                total_dollars_value: total_dollars_value
            }

            total_ether_value_in_wei += p_l.total_ether_value
            total_st_value_in_wei += p_l.total_simple_token_value
            @all_time_data[:total_dollars_value] += total_dollars_value
          end

          @all_time_data[:total_ethereum]  = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_ether_value_in_wei)
          @all_time_data[:total_tokens_sold] = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_st_value_in_wei)
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
                  total_filtered_recs: @curr_page_data.length
              },
              curr_page_data: @curr_page_data,
              all_time_data: @all_time_data
          }

        end

      end

    end

  end

end
