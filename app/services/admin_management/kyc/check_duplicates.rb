module AdminManagement

  module Kyc

    class CheckDuplicates < ServicesBase


      # TODO::Change Md5 logic
      # Initialize
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # @param [Integer] user_id (mandatory) - user id
      # @param [AR] client (mandatory) - client obj
      #
      # @return [AdminManagement::Kyc::CheckDuplicates]
      #
      def initialize(params)
        super
        @user_id = @params[:user_id].to_i
        @client = @params[:client]

        @client_id = @client.id

        @user_kyc_details = nil
        @md5_user_extended_details = nil

        @duplicate_log_ids = []
        @duplicate_user_ids = []

        @new_duplicate_md5_data = {
            GlobalConstant::UserKycDuplicationLog.document_id_with_country_duplicate_type => [],
            GlobalConstant::UserKycDuplicationLog.ethereum_duplicate_type => [],
            GlobalConstant::UserKycDuplicationLog.only_document_id_duplicate_type => [],
            GlobalConstant::UserKycDuplicationLog.address_duplicate_type => []
        }

        @dup_user_kyc_detail_objects = {}
        @new_duplicate_user_ids = []
        @user_kyc_active_duplicate_log_sql_values = []
        @user_kyc_inactive_duplicate_log_sql_values = []
      end

      # Perform
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def perform
        r = validate
        return r unless r.success?

        fetch_user_current_kyc_details

        return success unless @user_kyc_details.unprocessed_kyc_duplicate_status?


        fetch_existing_duplicate_data
        if @duplicate_log_ids.present?
          update_duplicate_logs_to_inactive
          unset_kyc_duplicate_status_of_previous_users
        end

        check_for_new_duplicates
        process_new_duplicate_data
        insert_new_dupliacte_logs
        set_kyc_duplicate_status_of_users

        set_email_duplicate_status_of_users if !@user_kyc_details.yes_email_duplicate_status?

        success
      end

      private

      # Fetch user details
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @user_kyc_details, @md5_user_extended_details
      #
      def fetch_user_current_kyc_details
        @user_kyc_details = UserKycDetail.using_client_shard(client: @client).where(user_id: @user_id).first

        @md5_user_extended_details = Md5UserExtendedDetail.using_client_shard(client: @client).
            where(user_extended_detail_id: @user_kyc_details.user_extended_detail_id).first
      end


      # Fetch user details
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @duplicate_log_ids, @duplicate_user_ids
      #
      def fetch_existing_duplicate_data
        # fetch as user1
        UserKycDuplicationLog.using_client_shard(client: @client).
            where(user1_id: @user_id, status: GlobalConstant::UserKycDuplicationLog.active_status).all.each do |d_log|
          @duplicate_log_ids << d_log.id
          @duplicate_user_ids << d_log.user2_id
        end
        # fetch as user2
        UserKycDuplicationLog.using_client_shard(client: @client).
            where(user2_id: @user_id, status: GlobalConstant::UserKycDuplicationLog.active_status).all.each do |d_log|
          @duplicate_log_ids << d_log.id
          @duplicate_user_ids << d_log.user1_id
        end
        @duplicate_user_ids.uniq!
      end

      # Update existing kyc details duplicate to inactive
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      def update_duplicate_logs_to_inactive
        UserKycDuplicationLog.using_client_shard(client: @client).where(id: @duplicate_log_ids).
            update_all(
                status: GlobalConstant::UserKycDuplicationLog.inactive_status,
                updated_at: current_time
            )
      end

      # Unset existing other's duplicates to inactive
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      def unset_kyc_duplicate_status_of_previous_users
        dup_user_ids = []
        dup_user_ids += UserKycDuplicationLog.using_client_shard(client: @client).where(
            user1_id: @duplicate_user_ids, status: GlobalConstant::UserKycDuplicationLog.active_status).pluck(:user1_id)
        dup_user_ids += UserKycDuplicationLog.using_client_shard(client: @client).where(
            user2_id: @duplicate_user_ids, status: GlobalConstant::UserKycDuplicationLog.active_status).pluck(:user2_id)

        filtered_non_duplicate_user_ids = @duplicate_user_ids - dup_user_ids

        if filtered_non_duplicate_user_ids.present?
          UserKycDetail.using_client_shard(client: @client).where(user_id: filtered_non_duplicate_user_ids).
              update_all(
                  kyc_duplicate_status: GlobalConstant::UserKycDetail.was_kyc_duplicate_status,
                  updated_at: current_time
              )
          UserKycDetail.using_client_shard(client: @client).bulk_flush(filtered_non_duplicate_user_ids)
        end
      end

      # Check for new duplicates
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @dup_user_kyc_detail_objects, @new_duplicate_md5_data
      #
      def check_for_new_duplicates

        new_duplicate_user_ids = []

        # By Nationality with document_id
        Md5UserExtendedDetail.using_client_shard(client: @client).where(nationality: @md5_user_extended_details.nationality, document_id_number: @md5_user_extended_details.document_id_number).all.each do |md5_obj|
          next if md5_obj.user_id == @user_id
          @new_duplicate_md5_data[GlobalConstant::UserKycDuplicationLog.document_id_with_country_duplicate_type] << md5_obj
          new_duplicate_user_ids << md5_obj.user_id
        end

        # By only document_id if not in above list
        Md5UserExtendedDetail.using_client_shard(client: @client).where(document_id_number: @md5_user_extended_details.document_id_number).all.each do |md5_obj|
          next if (md5_obj.user_id == @user_id) || (new_duplicate_user_ids.include?(md5_obj.user_id))
          @new_duplicate_md5_data[GlobalConstant::UserKycDuplicationLog.only_document_id_duplicate_type] << md5_obj
          new_duplicate_user_ids << md5_obj.user_id
        end

        if @md5_user_extended_details.ethereum_address.present?
          # By Ethereum address
          Md5UserExtendedDetail.using_client_shard(client: @client).where(ethereum_address: @md5_user_extended_details.ethereum_address).all.each do |md5_obj|
            next if md5_obj.user_id == @user_id
            @new_duplicate_md5_data[GlobalConstant::UserKycDuplicationLog.ethereum_duplicate_type] << md5_obj
            new_duplicate_user_ids << md5_obj.user_id
          end
        end

        if @md5_user_extended_details.street_address.present? && @md5_user_extended_details.city.present? && @md5_user_extended_details.state.present?
          # By Address
          Md5UserExtendedDetail.using_client_shard(client: @client).where(street_address: @md5_user_extended_details.street_address, city: @md5_user_extended_details.city, state: @md5_user_extended_details.state).all.each do |md5_obj|
            next if md5_obj.user_id == @user_id
            @new_duplicate_md5_data[GlobalConstant::UserKycDuplicationLog.address_duplicate_type] << md5_obj
            new_duplicate_user_ids << md5_obj.user_id
          end
        end

        return {} if new_duplicate_user_ids.blank?

        new_duplicate_user_ids.uniq!

        @dup_user_kyc_detail_objects = UserKycDetail.using_client_shard(client: @client).where(client_id: @client_id,
                                                                                               status: GlobalConstant::UserKycDetail.active_status,
                                                                                               user_id: new_duplicate_user_ids).
            select(:user_id, :user_extended_detail_id).all.index_by(&:user_id)
      end

      # Create bulk insert queries and set other user ids
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @user_kyc_active_duplicate_log_sql_values, user_kyc_inactive_duplicate_log_sql_values, @new_duplicate_user_ids
      #
      def process_new_duplicate_data
        return {} if @dup_user_kyc_detail_objects.blank?

        @new_duplicate_md5_data.each do |duplicate_type, md5_objs|

          md5_objs.each do |md5_obj|
            dup_user_kyc_obj = @dup_user_kyc_detail_objects[md5_obj.user_id]
            next if dup_user_kyc_obj.blank?

            if dup_user_kyc_obj.user_extended_detail_id == md5_obj.user_extended_detail_id
              @user_kyc_active_duplicate_log_sql_values << add_row_in_db_format(
                  duplicate_type,
                  md5_obj,
                  GlobalConstant::UserKycDuplicationLog.active_status)
              @new_duplicate_user_ids << md5_obj.user_id
            else
              @user_kyc_inactive_duplicate_log_sql_values << add_row_in_db_format(
                  duplicate_type,
                  md5_obj,
                  GlobalConstant::UserKycDuplicationLog.inactive_status)
            end

          end

          @new_duplicate_user_ids.uniq!
        end
      end

      # Create bulk insert query
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # @return [String]
      #
      def add_row_in_db_format(duplicate_type, md5_obj, status)
        "(#{@user_id}, #{md5_obj.user_id}, #{@md5_user_extended_details.user_extended_detail_id}, #{md5_obj.user_extended_detail_id}, #{duplication_type_int(duplicate_type)}, #{duplication_status_int(status)}, '#{current_time}', '#{current_time}')"
      end

      # Fire bulk update
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      def insert_new_dupliacte_logs
        sql_data = @user_kyc_active_duplicate_log_sql_values + @user_kyc_inactive_duplicate_log_sql_values
        UserKycDuplicationLog.using_client_shard(client: @client).bulk_insert(sql_data) if sql_data.present?
      end

      # Add active duplicate status
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      def set_kyc_duplicate_status_of_users
        if @new_duplicate_user_ids.present?
          @new_duplicate_user_ids << @user_id
          UserKycDetail.using_client_shard(client: @client).where(client_id: @client_id, user_id: @new_duplicate_user_ids).
              where.not(kyc_duplicate_status: GlobalConstant::UserKycDetail.is_kyc_duplicate_status).
              update_all(
                  kyc_duplicate_status: GlobalConstant::UserKycDetail.is_kyc_duplicate_status,
                  updated_at: current_time
              )
          UserKycDetail.using_client_shard(client: @client).bulk_flush(@new_duplicate_user_ids)
        else
          kyc_duplicate_status = @user_kyc_inactive_duplicate_log_sql_values.present? ?
                                     GlobalConstant::UserKycDetail.was_kyc_duplicate_status :
                                     GlobalConstant::UserKycDetail.never_kyc_duplicate_status

          UserKycDetail.using_client_shard(client: @client).
              where(client_id: @client_id, id: @user_kyc_details.id,
                    user_extended_detail_id: @user_kyc_details.user_extended_detail_id).
              update_all(
                  kyc_duplicate_status: kyc_duplicate_status,
                  updated_at: current_time
              )
          UserKycDetail.using_client_shard(client: @client).bulk_flush([@user_kyc_details.user_id])
        end
      end

      # Update email duplicate status
      #
      # * Author: aman
      # * Date: 20/10/2017
      # * Reviewed By: Sunil
      #
      def set_email_duplicate_status_of_users
        duplicate_email_user_ids = []
        # fetch as user1
        duplicate_email_user_ids += UserEmailDuplicationLog.using_client_shard(client: @client).
            where(user1_id: @user_id, status: GlobalConstant::UserEmailDuplicationLog.active_status).pluck(:user2_id)

        # fetch as user2
        duplicate_email_user_ids += UserEmailDuplicationLog.using_client_shard(client: @client).
            where(user2_id: @user_id, status: GlobalConstant::UserEmailDuplicationLog.active_status).pluck(:user1_id)

        duplicate_email_user_ids_with_kyc_done = UserKycDetail.using_client_shard(client: @client).where(client_id: @client_id,
                                                                                                         status: GlobalConstant::UserKycDetail.active_status,
                                                                                                         user_id: duplicate_email_user_ids).pluck(:user_id)

        duplicate_email_user_ids_with_kyc_done << @user_id if duplicate_email_user_ids_with_kyc_done.present?

        if duplicate_email_user_ids_with_kyc_done.present?
          UserKycDetail.using_client_shard(client: @client).where(
              client_id: @client_id,
              status: GlobalConstant::UserKycDetail.active_status,
              user_id: duplicate_email_user_ids_with_kyc_done,
              email_duplicate_status: GlobalConstant::UserKycDetail.no_email_duplicate_status
          ).
              update_all(
                  email_duplicate_status: GlobalConstant::UserKycDetail.yes_email_duplicate_status,
                  updated_at: current_time
              )
          UserKycDetail.using_client_shard(client: @client).bulk_flush(duplicate_email_user_ids_with_kyc_done)
        end

      end

      # Duplicate types
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Integer]
      #
      def duplication_type_int(duplicate_type)
        UserKycDuplicationLog.using_client_shard(client: @client).duplicate_types[duplicate_type]
      end

      # Active duplicate status
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Integer]
      #
      def duplication_status_int(status)
        @duplication_status_int = UserKycDuplicationLog.using_client_shard(client: @client).statuses[status]
      end

      # Get current time in string
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By: Sunil
      #
      # @return [String]
      #
      def current_time
        @current_time ||= Time.now.to_s(:db)
      end

    end

  end

end