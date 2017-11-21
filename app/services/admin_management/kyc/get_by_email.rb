module AdminManagement

  module Kyc

    class GetByEmail < ServicesBase

      # Initialize
      #
      # * Author: Alpesh
      # * Date: 20/11/2017
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [String] query (mandatory) - search term to find case
      #
      # @return [AdminManagement::Kyc::GetByEmail]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @query = @params[:query]
        @limit = 10

        @user_ids = []
        @matching_users = {}
        @user_kycs = {}
        @api_response = {}
      end

      # Perform
      #
      # * Author: Alpesh
      # * Date: 20/11/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        fetch_records

        api_response

      end

      private

      # Fetch related entities
      #
      # * Author: Alpesh
      # * Date: 20/11/2017
      # * Reviewed By:
      #
      # Sets @matching_users, @user_ids, @user_kycs
      #
      def fetch_records
        User.where("email like ?", "#{@query}%").select("id, email").limit(@limit).each do |usr|
          @user_ids << usr.id
          @matching_users[usr.id] = usr
        end
        return if @matching_users.blank?

        @user_kycs = UserKycDetail.where(user_id: @user_ids).select("id, user_id").all

      end

      # Format and send response.
      #
      # * Author: Alpesh
      # * Date: 20/11/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def api_response

        @user_kycs.each do |u_k|
          @api_response[u_k.id] = @matching_users[u_k.user_id].email
        end

        success_with_data(@api_response)
      end

    end

  end

end
