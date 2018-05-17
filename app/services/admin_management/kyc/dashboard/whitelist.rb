module AdminManagement

  module Kyc

    module Dashboard

      class Whitelist < AdminManagement::Kyc::Dashboard::Base

        # # Initialize
        # #
        # # * Author: Alpesh
        # # * Date: 24/10/2017
        # # * Reviewed By: Sunil
        # #
        # # @params [Integer] admin_id (mandatory) - logged in admin
        # # @params [Integer] client_id (mandatory) - logged in admin's client id
        # # @params [Hash] filters (optional)
        # # @params [Hash] sortings (optional)
        # # @params [Integer] page_number (optional)
        # #
        # # @return [AdminManagement::Kyc::Dashboard::Whitelist]
        # #
        # def initialize(params)
        #   super
        #
        #   @total_filtered_kycs = 0
        #   @user_kycs = []
        #   @user_extended_detail_ids = []
        #   @user_extended_details = {}
        #   @md5_user_extended_details = {}
        #   @admin_ids = []
        #   @admin_details = {}
        #
        #   @curr_page_data = []
        #   @api_response_data = {}
        # end
        #
        # # Perform
        # #
        # # * Author: Alpesh
        # # * Date: 24/10/2017
        # # * Reviewed By: Sunil
        # #
        # # @return [Result::Base]
        # #
        # def perform
        #   r = validate_and_sanitize
        #   return r unless r.success?
        #
        #   r = validate_for_whitelist_access
        #   return r unless r.success?
        #
        #   fetch_whitelisted_kyc_details
        #
        #   fetch_user_details
        #
        #   set_current_page_data
        #
        #   set_api_response_data
        #
        #   success_with_data(@api_response_data)
        #
        # end
        #
        # private
        #
        # # check if client has whitelist setup
        # #
        # # * Author: Aman
        # # * Date: 26/12/2017
        # # * Reviewed By:
        # #
        # # @return [Result::Base]
        # #
        # def validate_for_whitelist_access
        #
        #   return error_with_data(
        #       'am_k_d_w_1',
        #       'Client has not completed whitelisting setup',
        #       'Client has not completed whitelisting setup',
        #       GlobalConstant::ErrorAction.default,
        #       {}
        #   ) unless @client.is_whitelist_setup_done?
        #
        #   success
        # end
        #
        # # Fetch all users' kyc detail
        # #
        # # * Author: Alpesh
        # # * Date: 24/10/2017
        # # * Reviewed By: Sunil
        # #
        # # Sets @user_kycs, @total_filtered_kycs
        # #
        # def fetch_whitelisted_kyc_details
        #   ar_relation = UserKycDetail.where(client_id: @client_id)
        #
        #   if @sortings[:sort_order] == 'asc'
        #     ar_relation = ar_relation.order('id ASC')
        #   else
        #     ar_relation = ar_relation.order('id DESC')
        #   end
        #
        #   ar_relation = ar_relation.kyc_admin_and_cynopsis_approved
        #
        #   if @filters.present?
        #     query_hash = {}
        #
        #     @filters.each do |fl_k, fl_v|
        #       query_hash[fl_k.to_sym] = fl_v if fl_v.present? && UserKycDetail::whitelist_statuses[fl_v].present?
        #     end
        #
        #     ar_relation = ar_relation.where(query_hash) if query_hash.present?
        #
        #   end
        #
        #   @total_filtered_kycs = ar_relation.count
        #   @user_kycs = ar_relation.limit(@page_size).offset(@offset).all
        #
        # end
        #
        # # Set API response data
        # #
        # # * Author: Alpesh
        # # * Date: 24/10/2017
        # # * Reviewed By: Sunil
        # #
        # # Sets @curr_page_data
        # #
        # def set_current_page_data
        #
        #   @user_kycs.each do |u_k|
        #     user_extended_detail = @user_extended_details[u_k.user_extended_detail_id]
        #     md5_user_extended_detail = @md5_user_extended_details[u_k.user_extended_detail_id]
        #     country_name = GlobalConstant::CountryNationality.country_name_for(md5_user_extended_detail.country)
        #     nationality_name = GlobalConstant::CountryNationality.nationality_name_for(md5_user_extended_detail.nationality)
        #
        #     @curr_page_data << {
        #         case_id: u_k.id,
        #         kyc_confirmed_at: Time.at(u_k.created_at.to_i).strftime("%d/%m/%Y %H:%M"),
        #         whitelist_status: u_k.whitelist_status,
        #         is_duplicate: u_k.show_duplicate_status.to_i,
        #         is_re_submitted: u_k.is_re_submitted?,
        #         submission_count: u_k.submission_count.to_i,
        #         name: "#{user_extended_detail.first_name} #{user_extended_detail.last_name}",
        #         country: country_name.titleize,
        #         nationality: nationality_name.titleize,
        #         last_acted_by: last_acted_by(u_k.last_acted_by.to_i),
        #         last_acted_timestamp: get_formatted_time(u_k.last_acted_timestamp)
        #     }
        #   end

        # end

      end

    end

  end

end
