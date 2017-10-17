module AdminManagement

  module Kyc

    class Dashboard < ServicesBase

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
      # @return [AdminManagement::Kyc::Dashboard]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @filters = @params[:filters]
        @sortings = @params[:sortings]
        @page_size = @params[:page_size]
        @offset = @params[:offset]

        @total_filtered_kycs = 0
        @user_kycs = []
        @user_extended_detail_ids = []
        @user_extended_details = {}
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

        fetch_user_kyc_details

        fetch_user_details

        set_current_page_data

        set_api_response_data

        success_with_data(@api_response_data)

      end

      private

      # Validate and sanitize
      #
      # * Author: Alpesh
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        @filters = {} if @filters.blank? || !@filters.is_a?(Hash)
        @sortings = {} if @sortings.blank? || !@sortings.is_a?(Hash)
        @page_size = 25 if @page_size.to_i < 1 || @page_size.to_i > 25
        @offset = 0 if @offset.to_i < 0

        success
      end

      # Fetch all users' kyc detail
      #
      # * Author: Alpesh
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @user_kycs, @total_filtered_kycs
      #
      def fetch_user_kyc_details
        ar_relation = UserKycDetail

        if @sortings[:sort_order] == 'inc'
          ar_relation = ar_relation.order('id ASC')
        else
          ar_relation = ar_relation.order('id DESC')
        end

        if @filters[:admin_status].present?
          ar_relation = ar_relation.where(admin_status: @filters[:admin_status])
        end

        if @filters[:cynopsis_status].present?
          ar_relation = ar_relation.where(cynopsis_status: @filters[:cynopsis_status])
        end

        @total_filtered_kycs = ar_relation.count
        @user_kycs = ar_relation.limit(@page_size).offset(@offset).all

      end

      # Fetch user other details
      #
      # * Author: Alpesh
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @admin_details, @user_extended_details
      #
      def fetch_user_details
        return if @user_kycs.blank?

        @user_kycs.each do |u_k|
          @user_extended_detail_ids << u_k.user_extended_detail_id
          @admin_ids << u_k.last_acted_by
        end

        @user_extended_details = UserExtendedDetail.where(id: @user_extended_detail_ids).index_by(&:id)

        if @admin_ids.present?
          @admin_details = Admin.select('id, name').where(id: @admin_ids.uniq).index_by(&:id)
        end

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

          @curr_page_data << {
              case_id: u_k.id,
              kyc_confirmed_at: Time.at(u_k.kyc_confirmed_at).strftime("%d/%m/%Y %H:%M"),
              admin_status: u_k.admin_status,
              cynopsis_status: u_k.cynopsis_status,
              is_duplicate: u_k.duplicate_status,
              is_re_submitted: u_k.is_re_submitted.to_i,
              name: "#{user_extended_detail.first_name} #{user_extended_detail.last_name}",
              country: user_extended_detail.country,
              nationality: user_extended_detail.nationality,
              last_acted_by: last_acted_by(u_k.last_acted_by.to_i)
          }
        end

      end

      # Last acted by
      #
      # * Author: Alpesh
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # @return [String]
      #
      def last_acted_by(last_acted_by_id)
        (last_acted_by_id > 0) ? @admin_details[last_acted_by_id].name : ''
      end

      # Set API response data
      #
      # * Author: Alpesh
      # * Date: 15/10/2017
      # * Reviewed By: sunil
      #
      # Sets @api_response_data
      #
      def set_api_response_data

        @api_response_data = {
            curr_page_data: @curr_page_data,
            meta: {
                page_number: @page_number,
                total_filtered_recs: @total_filtered_kycs
            }
        }

      end

    end

  end

end
