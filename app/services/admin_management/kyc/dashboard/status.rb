module AdminManagement

  module Kyc

    module Dashboard

      class Status < AdminManagement::Kyc::Dashboard::Base

        # Initialize
        #
        # * Author: Aman
        # * Date: 24/04/2018
        # * Reviewed By:
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Hash] filters (optional)
        # @params [Hash] sortings (optional)
        # @params [Integer] page_number (optional)
        #
        # @return [AdminManagement::Kyc::Dashboard::Status]
        #
        def initialize(params)
          super

          @total_filtered_kycs = 0
          @user_kycs = []

          @user_extended_detail_ids = []
          @user_extended_details = {}
          @md5_user_extended_details = {}
          @admin_ids = []
          @admin_details = {}

          @curr_page_data = []
          @api_response_data = {}
        end

        # Perform
        #
        # * Author: Alpesh
        # * Date: 24/10/2017
        # * Reviewed By: Sunil
        #
        # @return [Result::Base]
        #
        def perform
          r = validate_and_sanitize
          return r unless r.success?

          fetch_user_kyc_details

          fetch_user_details

          set_current_page_data

          set_api_response_data

          success_with_data(@api_response_data)

        end

        private

        # Fetch all users' kyc detail
        #
        # * Author: Alpesh
        # * Date: 24/10/2017
        # * Reviewed By: Sunil
        #
        # Sets @user_kycs, @total_filtered_kycs
        #
        def fetch_user_kyc_details
          ar_relation = UserKycDetail.where(client_id: @client_id)
          ar_relation = ar_relation.filter_by(@filters)
          ar_relation = ar_relation.sorting_by(@sortings)

          offset = 0
          offset = @page_size * (@page_number - 1) if @page_number > 1
          @user_kycs = ar_relation.limit(@page_size).offset(offset).all
          @total_filtered_kycs = ar_relation.count
        end

        # Set API response data
        #
        # * Author: Alpesh
        # * Date: 24/10/2017
        # * Reviewed By: Sunil
        #
        # Sets @curr_page_data
        #
        def set_current_page_data

          @user_kycs.each do |u_k|
            user_extended_detail = @user_extended_details[u_k.user_extended_detail_id]
            md5_user_extended_detail = @md5_user_extended_details[u_k.user_extended_detail_id]
            country_name = GlobalConstant::CountryNationality.country_name_for(md5_user_extended_detail.country)
            nationality_name = GlobalConstant::CountryNationality.nationality_name_for(md5_user_extended_detail.nationality)

            duplicate_type = get_duplicate_type(u_k.user_extended_detail_id)

            @curr_page_data << {
                id: u_k.id,
                name: "#{user_extended_detail.first_name} #{user_extended_detail.last_name}",
                kyc_confirmed_at: get_formatted_time(u_k.kyc_confirmed_at),
                admin_status: u_k.admin_status,
                cynopsis_status: u_k.cynopsis_status,
                whitelist_status: u_k.whitelist_status,
                country: country_name.titleize,
                nationality: nationality_name.titleize,
                is_re_submitted: u_k.is_re_submitted?,
                submission_count: u_k.submission_count.to_i,
                is_duplicate: u_k.show_duplicate_status.to_i,
                last_acted_by: last_acted_by(u_k.last_acted_by.to_i),
                last_acted_timestamp: get_formatted_time(u_k.last_acted_timestamp),
                duplicate_type: duplicate_type,
            }
          end

        end

      end

    end

  end

end
