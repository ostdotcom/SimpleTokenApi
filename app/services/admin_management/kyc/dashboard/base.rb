module AdminManagement

  module Kyc

    module Dashboard

      class Base < ServicesBase


        KYC_FILTERS = {

        }

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 24/10/2017
        # * Reviewed By: Sunil
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Hash] filters (optional)
        # @params [Hash] sortings (optional)
        # @params [Integer] page_number (optional)
        #
        # @return [AdminManagement::Kyc::Dashboard::Base]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @client_id = @params[:client_id]
          @filters = @params[:filters]
          @sortings = @params[:sortings]
          @page_size = @params[:page_size]
          @offset = @params[:offset]
        end

        private

        # Validate and sanitize
        #
        # * Author: Alpesh
        # * Date: 24/10/2017
        # * Reviewed By: Sunil
        #
        def validate_and_sanitize
          r = validate
          return r unless r.success?

          @filters = {} if @filters.blank? || !(@filters.is_a?(Hash) || @filters.is_a?(ActionController::Parameters))
          @sortings = {} if @sortings.blank? || !(@sortings.is_a?(Hash) || @sortings.is_a?(ActionController::Parameters))
          @page_size = 50 if @page_size.to_i < 1 || @page_size.to_i > 50
          @offset = 0 if @offset.to_i <= 0

          r = fetch_and_validate_client
          return r unless r.success?

          success
        end

        # Fetch user other details
        #
        # * Author: Alpesh
        # * Date: 24/10/2017
        # * Reviewed By: Sunil
        #
        # Sets @admin_details, @user_extended_details, @md5_user_extended_details, @admin_ids, @user_extended_detail_ids
        #
        def fetch_user_details
          return if @user_kycs.blank?

          @user_kycs.each do |u_k|
            @user_extended_detail_ids << u_k.user_extended_detail_id
            @admin_ids << u_k.last_acted_by
          end

          @user_extended_details = UserExtendedDetail.where(id: @user_extended_detail_ids).index_by(&:id)
          @md5_user_extended_details = Md5UserExtendedDetail.select('id, user_extended_detail_id, country, nationality').
              where(user_extended_detail_id: @user_extended_detail_ids).index_by(&:user_extended_detail_id)

          if @admin_ids.present?
            @admin_details = Admin.select('id, name').where(id: @admin_ids.uniq).index_by(&:id)
          end

        end

        # Last acted by
        #
        # * Author: Alpesh
        # * Date: 24/10/2017
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
        # * Date: 24/10/2017
        # * Reviewed By: sunil
        #
        # Sets @api_response_data
        #
        def set_api_response_data


          dummy_meta = {
              page_number: 1,
              page_size: 10,
              total_records: 100,
              page_payload: {},
              filters: @filters,
              sortings: @sortings
          }

          dummy_data = {
              meta: dummy_meta,
              result_set: 'user_kyc_list',
              user_kyc_list: @curr_page_data
          }

          @api_response_data = {
              curr_page_data: @curr_page_data,
              meta: {
                  page_offset: @offset,
                  page_size: @page_size,
                  total_filtered_recs: @total_filtered_kycs
              },
              client_setup: {
                  has_email_setup: @client.is_email_setup_done?,
                  has_whitelist_setup: @client.is_whitelist_setup_done?
              }
          }.merge(dummy_data)

        end

      end

    end

  end

end
