module AdminManagement

  module Kyc

    class Dashboard < ServicesBase

      # Initialize
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # @param [Integer] admin_id (mandatory) - logged in admin
      # @param [Hash] filters (optional)
      # @param [Hash] sortings (optional)
      # @param [Integer] page_number (optional)
      #
      # @return [AdminManagement::Kyc::Dashboard]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @filters = @params[:filters] || {}
        @sortings = @params[:sortings] || {sort_order: 'inc'}
        @page_number = @params[:page_number] || 1

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
        r = validate
        return r unless r.success?

        limit = 25
        offset = (@page_number.to_i - 1) * limit

        ar_relation = UserKycDetail.limit(limit).offset(offset)

        if @sortings[:sort_order] == 'desc'
          ar_relation = ar_relation.order('id DESC')
        end

        if @filters[:admin_status].present?
          ar_relation = ar_relation.where(admin_status: @filters[:admin_status])
        end

        if @filters[:cynopsis_status].present?
          ar_relation = ar_relation.where(cynopsis_status: @filters[:cynopsis_status])
        end

        ar_relation.all.each do |ukd|

        end

        success_with_data(@api_response_data)

      end

      private



    end

  end

end
