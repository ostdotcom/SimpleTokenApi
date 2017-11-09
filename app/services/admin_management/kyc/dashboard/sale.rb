module AdminManagement

  module Kyc

    module Dashboard

      class Sale < ServicesBase

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 09/11/2017
        # * Reviewed By:
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
        # * Reviewed By:
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
        # * Reviewed By:
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
        # * Reviewed By:
        #
        # Sets @total_filtered_kycs, @curr_page_data
        #
        def fetch_purchase_data

          @total_filtered_kycs = PurchaseLog.group("pst_day_start_timestamp").count

          PurchaseLog
              .select("pst_day_start_timestamp, sum(ether_value) as total_ether_value, sum(simple_token_value) as total_simple_token_value, sum(usd_value) as total_usd_value")
              .limit(@page_size).offset(@offset)
              .group("pst_day_start_timestamp")
              .order("pst_day_start_timestamp DESC")
              .each do |p_l|

            @curr_page_data << {
                day_timestamp: Time.at(p_l.pst_day_start_timestamp).strftime("%d/%m/%Y"),
                total_etherium: p_l.total_ether_value,
                total_tokens_sold: p_l.total_simple_token_value,
                total_dollers_value: p_l.total_usd_value
            }

          end

        end

        # Set API response data
        #
        # * Author: Alpesh
        # * Date: 09/11/2017
        # * Reviewed By:
        #
        # Sets @api_response_data
        #
        def set_api_response_data

          @api_response_data = {
              curr_page_data: @curr_page_data,
              meta: {
                  page_offset: @offset,
                  page_size: @page_size,
                  total_filtered_recs: @total_filtered_kycs.length
              }
          }

        end

      end

    end

  end

end
