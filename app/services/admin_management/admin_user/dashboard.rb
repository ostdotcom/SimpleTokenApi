module AdminManagement

  module AdminUser

    class Dashboard < ServicesBase

      # Initialize
      #
      # * Author: AMan
      # * Date: 24/04/2018
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      #
      # @return [AdminManagement::AdminUser::Dashboard]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]

        @admin = nil
        @client = nil

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
        #   r = validate_and_sanitize
        #   return r unless r.success?
        #
        #   fetch_user_kyc_details
        #
        #   fetch_user_details
        #
        #   set_current_page_data
        #
        #   set_api_response_data
        #
        #   success_with_data(@api_response_data)
        #
      end
      #
      # private
      #
      # # Fetch all users' kyc detail
      # #
      # # * Author: Alpesh
      # # * Date: 24/10/2017
      # # * Reviewed By: Sunil
      # #
      # # Sets @user_kycs, @total_filtered_kycs
      # #
      # def fetch_user_kyc_details
      #   ar_relation = UserKycDetail.where(client_id: @client_id)
      #   ar_relation = ar_relation.filter_by(@filters)
      #   ar_relation = ar_relation.sorting_by(@sortings)
      #
      #   offset = 0
      #   offset = @page_size * (@page_number - 1) if @page_number > 1
      #   @user_kycs = ar_relation.limit(@page_size).offset(offset).all
      #   @total_filtered_kycs = ar_relation.count
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
      #     duplicate_type = get_duplicate_type(u_k.user_extended_detail_id)
      #
      #     @curr_page_data << {
      #         id: u_k.id,
      #         name: "#{user_extended_detail.first_name} #{user_extended_detail.last_name}",
      #         kyc_confirmed_at: get_formatted_time(u_k.kyc_confirmed_at),
      #         admin_status: u_k.admin_status,
      #         cynopsis_status: u_k.cynopsis_status,
      #         whitelist_status: u_k.whitelist_status,
      #         country: country_name.titleize,
      #         nationality: nationality_name.titleize,
      #         is_re_submitted: u_k.is_re_submitted?,
      #         submission_count: u_k.submission_count.to_i,
      #         is_duplicate: u_k.show_duplicate_status.to_i,
      #         last_acted_by: last_acted_by(u_k.last_acted_by.to_i),
      #         last_acted_timestamp: get_formatted_time(u_k.last_acted_timestamp),
      #         duplicate_type: duplicate_type,
      #     }
      #   end
      #
      # end


      #
      # private
      #
      # # Validate and sanitize
      # #
      # # * Author: Alpesh
      # # * Date: 24/10/2017
      # # * Reviewed By: Sunil
      # #
      # def validate_and_sanitize
      #   r = validate
      #   return r unless r.success?
      #
      #   @filters = {} if @filters.blank? || !(@filters.is_a?(Hash) || @filters.is_a?(ActionController::Parameters))
      #   @sortings = {} if @sortings.blank? || !(@sortings.is_a?(Hash) || @sortings.is_a?(ActionController::Parameters))
      #
      #
      #   if @filters.present?
      #
      #     error_data = {}
      #
      #     @filters.each do |key, val|
      #
      #       if GlobalConstant::UserKycDetail.filters[key.to_s].blank?
      #         return error_with_data(
      #             'am_k_d_vas_1',
      #             'Invalid Parameters.',
      #             'Invalid Filter type passed',
      #             GlobalConstant::ErrorAction.default,
      #             {},
      #             {}
      #         )
      #       end
      #
      #       filter_data = GlobalConstant::UserKycDetail.filters[key][val]
      #       error_data[key] = 'invalid value for filter' if filter_data.nil?
      #     end
      #
      #     return error_with_data(
      #         'am_k_d_vas_2',
      #         'Invalid Filter Parameter value',
      #         '',
      #         GlobalConstant::ErrorAction.default,
      #         {},
      #         error_data
      #     ) if error_data.present?
      #
      #   end
      #
      #
      #   if @sortings.present?
      #     error_data = {}
      #
      #     @sortings.each do |key, val|
      #
      #       if GlobalConstant::UserKycDetail.sorting[key.to_s].blank?
      #         return error_with_data(
      #             'am_k_d_vas_3',
      #             'Invalid Parameters.',
      #             'Invalid Sort type passed',
      #             GlobalConstant::ErrorAction.default,
      #             {},
      #             {}
      #         )
      #       end
      #
      #       sort_data = GlobalConstant::UserKycDetail.sorting[key][val]
      #       error_data[key] = 'invalid value for sorting' if sort_data.nil?
      #     end
      #
      #     return error_with_data(
      #         'am_k_d_vas_4',
      #         'Invalid Sort Parameter value',
      #         '',
      #         GlobalConstant::ErrorAction.default,
      #         {},
      #         error_data
      #     ) if error_data.present?
      #   end
      #
      #   @page_number = 1 if @page_number < 1
      #   @page_size = 20 if @page_size == 0 || @page_size > 100
      #
      #   r = fetch_and_validate_client
      #   return r unless r.success?
      #
      #   r = fetch_and_validate_admin
      #   return r unless r.success?
      #
      #   success
      # end
      #
      # # Fetch user other details
      # #
      # # * Author: Alpesh
      # # * Date: 24/10/2017
      # # * Reviewed By: Sunil
      # #
      # # Sets @admin_details, @user_extended_details, @md5_user_extended_details, @admin_ids, @user_extended_detail_ids
      # #      @duplicate_user_extended_detail_ids, @email_duplicate_user_extended_detail_ids, @duplicate_user_ids
      # #
      # def fetch_user_details
      #   return if @user_kycs.blank?
      #
      #   @user_kycs.each do |u_k|
      #     @user_extended_detail_ids << u_k.user_extended_detail_id
      #     @admin_ids << u_k.last_acted_by if u_k.last_acted_by.present?
      #     if u_k.email_duplicate_status == GlobalConstant::UserKycDetail.yes_email_duplicate_status
      #       @email_duplicate_user_extended_detail_ids << u_k.user_extended_detail_id
      #     else
      #       if u_k.check_duplicate_status
      #         @duplicate_user_ids << u_k.user_id
      #         @duplicate_user_extended_detail_ids << u_k.user_extended_detail_id
      #       end
      #     end
      #   end
      #
      #   fetch_duplicate_type
      #
      #   @user_extended_details = UserExtendedDetail.where(id: @user_extended_detail_ids).index_by(&:id)
      #   @md5_user_extended_details = Md5UserExtendedDetail.select('id, user_extended_detail_id, country, nationality').
      #       where(user_extended_detail_id: @user_extended_detail_ids).index_by(&:user_extended_detail_id)
      #
      #   if @admin_ids.present?
      #     @admin_details = Admin.select('id, name').where(id: @admin_ids.uniq).index_by(&:id)
      #   end
      #
      # end
      #
      # # fetch duplicate kyc data if there are any
      # #
      # # * Author: Aman
      # # * Date: 12/10/2017
      # # * Reviewed By:
      # #
      # # Sets @duplicate_kyc_type_data
      # #
      # def fetch_duplicate_type
      #   return if @duplicate_user_extended_detail_ids.blank?
      #
      #   duplicate_data = []
      #
      #   duplicate_data += UserKycDuplicationLog.select('distinct user_extended_details1_id as user_extended_details_id, duplicate_type').
      #       where(user1_id: @duplicate_user_ids, status: GlobalConstant::UserKycDuplicationLog.active_status, user_extended_details1_id: @duplicate_user_extended_detail_ids).all
      #   duplicate_data += UserKycDuplicationLog.select('distinct user_extended_details2_id as user_extended_details_id, duplicate_type').
      #       where(user2_id: @duplicate_user_ids, status: GlobalConstant::UserKycDuplicationLog.active_status, user_extended_details2_id: @duplicate_user_extended_detail_ids).all
      #
      #   duplicate_data.each do |duplicate|
      #
      #     @duplicate_kyc_type_data[duplicate.user_extended_details_id] ||= duplicate.duplicate_type
      #
      #     if @duplicate_kyc_type_data[duplicate.user_extended_details_id].blank? ||
      #         UserKycDuplicationLog.duplicate_types[@duplicate_kyc_type_data[duplicate.user_extended_details_id]] >
      #             UserKycDuplicationLog.duplicate_types[duplicate.duplicate_type]
      #
      #       @duplicate_kyc_type_data[duplicate.user_extended_details_id] = duplicate.duplicate_type
      #     end
      #   end
      #
      # end
      #
      # # Last acted by
      # #
      # # * Author: Alpesh
      # # * Date: 24/10/2017
      # # * Reviewed By: Sunil
      # #
      # # @return [String]
      # #
      # def last_acted_by(last_acted_by_id)
      #   (last_acted_by_id > 0) ? @admin_details[last_acted_by_id].name : nil
      # end
      #
      # # Get Duplicate type of user if present
      # #
      # # * Author: Aman
      # # * Date: 25/04/2018
      # # * Reviewed By:
      # #
      # # @return [String]
      # #
      # def get_duplicate_type(user_extended_detail_id)
      #   if @email_duplicate_user_extended_detail_ids.include?(user_extended_detail_id)
      #     return GlobalConstant::UserEmailDuplicationLog.email_duplicate_type
      #   else
      #     @duplicate_kyc_type_data[user_extended_detail_id]
      #   end
      # end
      #
      # # Get Formatted Time
      # #
      # # * Author: Aman
      # # * Date: 24/04/2018
      # # * Reviewed By:
      # #
      # # @return [Integer] returns Timestamp
      # #
      # def get_formatted_time(timestamp)
      #   timestamp.to_i > 0 ? Util::DateTimeHelper.get_formatted_time(timestamp) : nil
      #   # Time.at(u_k.kyc_confirmed_at).strftime("%d/%m/%Y %H:%M")
      # end
      #
      # # Set API response data
      # #
      # # * Author: Alpesh
      # # * Date: 24/10/2017
      # # * Reviewed By: sunil
      # #
      # # Sets @api_response_data
      # #
      # def set_api_response_data
      #
      #   meta = {
      #       page_number: @page_number,
      #       total_records: @total_filtered_kycs,
      #       page_payload: {
      #       },
      #       page_size: @page_size,
      #       filters: @filters,
      #       sortings: @sortings,
      #   }
      #
      #   data = {
      #       meta: meta,
      #       result_set: 'user_kyc_list',
      #       user_kyc_list: @curr_page_data
      #       # client_setup: {
      #       #     has_email_setup: @client.is_email_setup_done?,
      #       #     has_whitelist_setup: @client.is_whitelist_setup_done?
      #       # }
      #   }
      #
      #   @api_response_data = data
      #
      # end


    end

  end

end
