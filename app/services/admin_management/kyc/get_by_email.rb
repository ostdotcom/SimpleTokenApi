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
      # @param [AR] client (mandatory) - client obj
      # @params [String] email (mandatory) - search term to find case
      #
      # @return [AdminManagement::Kyc::GetByEmail]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client = @params[:client]
        @email = @params[:email]

        @page_size = 10
        @client_id = @params[:client_id]

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
        User.using_client_shard(client: @client).
            where(client_id: @client_id).where("email like ?", "#{@email}%").select("id, email").limit(@page_size).each do |usr|
          @user_ids << usr.id
          @matching_users[usr.id] = usr
        end
        return if @matching_users.blank?

        @user_kycs = UserKycDetail.using_client_shard(client: @client).
            where(client_id: @client_id, user_id: @user_ids).select("id, user_id").all

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

        search_data = []
        @user_kycs.each do |u_k|
          search_data << {
              id: u_k.id,
              email: @matching_users[u_k.user_id].email
          }
        end

        meta = {
            page_number: 1,
            total_records: @user_kycs.length,
            page_payload: {
            },
            page_size: @page_size
        }

        @api_response = {
            meta: meta,
            result_set: 'user_search_list',
            user_search_list: search_data,
        }

        success_with_data(@api_response)
      end

    end

  end

end
