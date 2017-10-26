module AdminManagement

  module Kyc

    module Dashboard

      class Base < ServicesBase

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
        # @return [AdminManagement::Kyc::Dashboard::Status]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @filters = @params[:filters]
          @sortings = @params[:sortings]
          @page_size = @params[:page_size]
          @offset = @params[:offset]
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

          @filters = {} if @filters.blank? || !(@filters.is_a?(Hash) || @filters.is_a?(ActionController::Parameters))
          @sortings = {} if @sortings.blank? || !(@sortings.is_a?(Hash) || @sortings.is_a?(ActionController::Parameters))
          @page_size = 25 if @page_size.to_i < 1 || @page_size.to_i > 25
          @offset = 0 if @offset.to_i <= 0

          success
        end


        # Fetch user other details
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # Sets @admin_details, @user_extended_details, @md5_user_extended_details
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
                  page_offset: @offset,
                  page_size: @page_size,
                  total_filtered_recs: @total_filtered_kycs
              }
          }

        end

      end

    end

  end

end
