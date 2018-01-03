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
          @tab_type = @params[:tab_type]

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

          r = validate_for_sale_dashboard_access
          return r unless r.success?

          @tab_type=='date' ? fetch_purchase_data(false) : fetch_purchase_data(true)

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
              'am_k_d_sd_1',
              'Client is not active',
              'Client is not active',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @client.status != GlobalConstant::Client.active_status

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
              'am_k_d_sd_2',
              'Client does not access for sale dashboard',
              'Client does not access for sale dashboard',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @client.id != GlobalConstant::TokenSale.st_token_sale_client_id

          success
        end

        # Set API response data
        #
        # * Author: Kushal
        # * Date: 13/11/2017
        # * Reviewed By:
        #
        # Sets @curr_page_data
        #
        def fetch_purchase_data(is_daywise)

          @all_time_data = { total_ethereum: 0, total_tokens_sold: 0, total_dollar_value: 0,
                             total_no_of_transaction: 0, overall_average_eth: 0, distinct_users: 0 }

          data_map, unique_users = {}, {}

          total_ether_value_in_wei, total_st_value_in_wei = 0 , 0

          PurchaseLog
              .select("id, ethereum_address, ether_wei_value, st_wei_value, usd_value,
                        block_creation_timestamp, pst_day_start_timestamp")
              .find_in_batches(batch_size: 1000) do |purchase_logs|

            purchase_logs.each do |p_l|
              current_day = is_daywise ? get_day(p_l.block_creation_timestamp) : p_l.pst_day_start_timestamp
              data_map[current_day] ||= {
                  date: is_daywise ? get_relative_date_wrt_sale_start_time(current_day) : get_date_in_pst(current_day),
                  total_ethereum_units: 0,
                  total_tokens_sold_units: 0,
                  total_dollar_value: 0,
                  day_no: current_day,
                  no_of_transaction: 0,
                  etherium_adresses: {}
              }
              data_map[current_day][:total_ethereum_units] += p_l.ether_wei_value
              data_map[current_day][:total_tokens_sold_units] += p_l.st_wei_value
              data_map[current_day][:total_dollar_value] += p_l.usd_value.to_f
              data_map[current_day][:no_of_transaction] += 1
              data_map[current_day][:etherium_adresses][p_l.ethereum_address] = 1
              @all_time_data[:total_dollar_value] += p_l.usd_value.to_f
              @all_time_data[:total_no_of_transaction] += 1
              unique_users[p_l.ethereum_address] = 1
              total_ether_value_in_wei += p_l.ether_wei_value
              total_st_value_in_wei += p_l.st_wei_value
            end

          end

          data_map.keys.sort.reverse.each do |i|
            data = data_map[i]
            next if data.blank?
            @curr_page_data << {
                date: data[:date],
                total_ethereum: GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(data[:total_ethereum_units]).to_f.round(2),
                total_tokens_sold: GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(data[:total_tokens_sold_units]).to_f.round(2),
                total_dollar_value: data[:total_dollar_value].round(2),
                day_no: data[:day_no],
                no_of_transaction: data[:no_of_transaction],
                average_eth: GlobalConstant::ConversionRate.
                    wei_to_basic_unit_in_string(data[:total_ethereum_units] / data[:etherium_adresses].length).to_f.round(2),
                distinct_users: data[:etherium_adresses].length
            }
          end

          @all_time_data[:total_ethereum]  = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_ether_value_in_wei).to_f.round(2)
          @all_time_data[:total_tokens_sold] = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_st_value_in_wei).to_f.round(2)
          @all_time_data[:total_dollar_value] = @all_time_data[:total_dollar_value].round(2)
          @all_time_data[:distinct_users] = unique_users.length
          @all_time_data[:overall_average_eth] = GlobalConstant::ConversionRate.
              wei_to_basic_unit_in_string(total_ether_value_in_wei / @all_time_data[:distinct_users]).to_f.round(2)


        end

        # Get the date in pst timezone
        #
        # * Author: Kushal
        # * Date: 14/11/2017
        # * Reviewed By:
        #
        # Return [String] date in pst
        #
        def get_date_in_pst(timestamp)
          Time.at(timestamp).in_time_zone('Pacific Time (US & Canada)').strftime("%d/%m/%Y")
        end

        # Get the date in utc timezone
        #
        # * Author: Kushal
        # * Date: 14/11/2017
        # * Reviewed By:
        #
        # Return [String] date in utc
        #
        def get_relative_date_wrt_sale_start_time(no_of_day)
          Time.at(GlobalConstant::TokenSale.early_access_start_date.to_i + no_of_day.days)
              .in_time_zone("UTC").strftime("%d/%m/%Y %H:%M:%S")
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
