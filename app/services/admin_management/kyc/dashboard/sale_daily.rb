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

          fetch_day_wise_purchase_data

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
        # * Author: Kushal
        # * Date: 13/11/2017
        # * Reviewed By:
        #
        # Sets @curr_page_data
        #
        def fetch_day_wise_purchase_data

          @all_time_data = { total_ethereum: 0, total_tokens_sold: 0, total_dollar_value: 0}

          daywise_data = {}

          total_ether_value_in_wei, total_st_value_in_wei, max_day = 0 , 0, 0
          PurchaseLog
              .select("id, ether_wei_value, st_wei_value, usd_value, block_creation_timestamp")
              .find_in_batches(batch_size: 1000) do |purchase_logs|

            purchase_logs.each do |p_l|
              current_day = get_day(p_l.block_creation_timestamp)
              daywise_data[current_day] ||= {
                  day_timestamp: Time.at(p_l.block_creation_timestamp).strftime("%d/%m/%Y"),
                  total_ethereum_units: 0,
                  total_tokens_sold_units: 0,
                  total_dollar_value: 0,
                  day_no: current_day
              }
              daywise_data[current_day][:total_ethereum_units] += p_l.ether_wei_value
              daywise_data[current_day][:total_tokens_sold_units] += p_l.st_wei_value
              daywise_data[current_day][:total_dollar_value] += p_l.usd_value.to_f
              @all_time_data[:total_dollar_value] += p_l.usd_value.to_f
              total_ether_value_in_wei += p_l.ether_wei_value
              total_st_value_in_wei += p_l.st_wei_value
              max_day = [max_day, current_day].max
            end
          end

          for i in (max_day).downto(0)
            data = daywise_data[i]
            next if data.blank?
            @curr_page_data << {
                day_timestamp: data[:day_timestamp],
                total_ethereum: GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(data[:total_ethereum_units]),
                total_tokens_sold: GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(data[:total_tokens_sold_units]),
                total_dollar_value: data[:total_dollar_value].round(2),
                day_no: data[:day_no]
            }
          end

          @all_time_data[:total_ethereum]  = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_ether_value_in_wei)
          @all_time_data[:total_tokens_sold] = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_st_value_in_wei)
          @all_time_data[:total_dollar_value] = @all_time_data[:total_dollar_value].round(2)

        end

        # Get the day number with respect to the start date of sale
        #
        # * Author: Kushal
        # * Date: 13/11/2017
        # * Reviewed By:
        #
        # Return day w.r.t sale date
        #
        def get_day(block_creation_time_in_utc)
          relative_timestamp = block_creation_time_in_utc - GlobalConstant::TokenSale.early_access_start_date.to_i
          relative_timestamp / (24 * 60 * 60)
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
