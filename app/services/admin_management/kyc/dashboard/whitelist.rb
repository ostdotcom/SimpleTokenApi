module AdminManagement

  module Kyc

    module Dashboard

      class Whitelist < AdminManagement::Kyc::Dashboard::Base

        # Initialize
        #
        # * Author: Kedar
        # * Date: 14/10/2017
        # * Reviewed By: Sunil
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Hash] filters (optional)
        # @params [Hash] sortings (optional)
        # @params [Integer] page_number (optional)
        #
        # @return [AdminManagement::Kyc::Dashboard::Whitelist]
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
        # * Author: Kedar
        # * Date: 14/10/2017
        # * Reviewed By: Sunil
        #
        # @return [Result::Base]
        #
        def perform
          r = validate_and_sanitize
          return r unless r.success?

          fetch_whitelisted_kyc_details

          fetch_user_details

          set_current_page_data

          set_api_response_data

          success_with_data(@api_response_data)

        end

        private

        # Fetch all users' kyc detail
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # Sets @user_kycs, @total_filtered_kycs
        #
        def fetch_whitelisted_kyc_details
          ar_relation = UserKycDetail

          if @sortings[:sort_order] == 'inc'
            ar_relation = ar_relation.order('id ASC')
          else
            ar_relation = ar_relation.order('id DESC')
          end

          ar_relation = ar_relation.where(cynopsis_status: GlobalConstant::UserKycDetail.cynopsis_approved_statuses)
          ar_relation = ar_relation.where(admin_status: GlobalConstant::UserKycDetail.admin_approved_statuses)

          if @filters.present?
            query_hash = {}

            if !@filters[:whitelist_status].nil?
              query_hash[:cynopsis_status] = GlobalConstant::UserKycDetail.cynopsis_approved_statuses
              query_hash[:admin_status] = GlobalConstant::UserKycDetail.admin_approved_statuses
            end

            @filters.each do |fl_k, fl_v|
              query_hash[fl_k.to_sym] = fl_v if fl_v.present? && UserKycDetail::whitelist_statuses[fl_v].present?
            end

            ar_relation = ar_relation.where(query_hash) if query_hash.present?

          end

          @total_filtered_kycs = ar_relation.count
          @user_kycs = ar_relation.limit(@page_size).offset(@offset).all

        end

        # Set API response data
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
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

            @curr_page_data << {
                case_id: u_k.id,
                kyc_confirmed_at: Time.at(u_k.kyc_confirmed_at).strftime("%d/%m/%Y %H:%M"),
                whitelist_status: u_k.whitelist_status,
                is_duplicate: u_k.show_duplicate_status.to_i,
                is_re_submitted: u_k.is_re_submitted.to_i,
                name: "#{user_extended_detail.first_name} #{user_extended_detail.last_name}",
                country: country_name.titleize,
                nationality: nationality_name.titleize,
                last_acted_by: last_acted_by(u_k.last_acted_by.to_i)
            }
          end

        end

      end

    end

  end

end
