module AdminManagement

  module Kyc

    class CheckDuplicates < ServicesBase

      # Initialize
      #
      # * Author: aman
      # * Date: 15/10/2017
      # * Reviewed By:
      #
      # @param [Integer] user_id (mandatory) - user id
      #
      # @return [AdminManagement::Kyc::CheckDetails]
      #
      def initialize(params)
        super
        @user_id = @params[:user_id]

        @user_kyc_details = nil
        @md5_user_extended_details = nil

        @duplicate_log_ids = []
        @duplicate_user_ids = []

        @new_duplicate_md5_data = {
            GlobalConstant::UserKycDuplicationLog.passport_with_country_duplicate_type => [],
            GlobalConstant::UserKycDuplicationLog.ethereum_duplicate_type => [],
            GlobalConstant::UserKycDuplicationLog.only_passport_duplicate_type => [],
            GlobalConstant::UserKycDuplicationLog.address_duplicate_type => []
        }

        @active_duplicate_extended_details_ids = []
        @new_duplicate_user_ids = []
        @user_kyc_duplicate_log_sql_values = []
      end

      def perform
        r = validate
        return r unless r.success?
        begin

          fetch_user_details

          fetch_duplicate_data

          if @duplicate_log_ids.present?
            update_duplicates_logs_to_inactive
            unset_duplicate_status_of_previous_users
          end

          check_for_new_duplicates
          remove_inactive_md5_data

          if @new_duplicate_user_ids.present?
            insert_new_dupliacte_logs
            set_duplicate_status_of_new_users
          end

          return success_with_data({
                                       is_duplicate: @new_duplicate_user_ids.present?
                                   })
        rescue => e
          return exception_with_data(
              e,
              'am_k_cd_1',
              'something went wrong',
              'something went wrong',
              GlobalConstant::ErrorAction.default,
              {user_id: @user_id}
          )
        end

      end

      def fetch_user_details
        @user_kyc_details = UserKycDetail.where(user_id: @user_id).first
        @md5_user_extended_details = Md5UserExtendedDetail.where(user_extended_detail_id: @user_kyc_details.user_extended_detail_id).first
      end

      def fetch_duplicate_data
        @duplicate_log_ids, @duplicate_user_ids = [], []

        UserKycDuplicationLog.where(user1_id: @user_id, status: GlobalConstant::UserKycDuplicationLog.active_status).all.each do |d_log|
          @duplicate_log_ids << d_log.id
          @duplicate_user_ids << d_log.user2_id
        end

        UserKycDuplicationLog.where(user2_id: @user_id, status: GlobalConstant::UserKycDuplicationLog.active_status).all.each do |d_log|
          @duplicate_log_ids << d_log.id
          @duplicate_user_ids << d_log.user1_id
        end

        @duplicate_log_ids.uniq!
        @duplicate_user_ids.uniq!
      end

      def update_duplicates_logs_to_inactive
        UserKycDuplicationLog.where(id: @duplicate_log_ids).update_all(status: GlobalConstant::UserKycDuplicationLog.inactive_status)
      end

      def unset_duplicate_status_of_previous_users
        dup_user_ids = []
        dup_user_ids += UserKycDuplicationLog.where(user1_id: @duplicate_user_ids, status: GlobalConstant::UserKycDuplicationLog.active_status).pluck(:user1_id)
        dup_user_ids += UserKycDuplicationLog.where(user2_id: @duplicate_user_ids, status: GlobalConstant::UserKycDuplicationLog.active_status).pluck(:user2_id)

        filtered_non_duplicate_user_ids = @duplicate_user_ids - dup_user_ids

        UserKycDetail.where(user_id: filtered_non_duplicate_user_ids).update_all(is_duplicate: GlobalConstant::UserKycDetail.false_status) if filtered_non_duplicate_user_ids.present?
      end


      def check_for_new_duplicates

        new_duplicate_extended_details_id = []

        Md5UserExtendedDetail.where(nationality: @md5_user_extended_details.nationality, passport_number: @md5_user_extended_details.passport_number).all.each do |md5_obj|
          next if md5_obj.user_id == @user_id

          @new_duplicate_md5_data[GlobalConstant::UserKycDuplicationLog.passport_with_country_duplicate_type] << md5_obj
          new_duplicate_extended_details_id << md5_obj.user_extended_detail_id
        end

        Md5UserExtendedDetail.where(passport_number: @md5_user_extended_details.passport_number).all.each do |md5_obj|
          next if (md5_obj.user_id == @user_id) || (new_duplicate_extended_details_id.include?(md5_obj.user_extended_detail_id))

          @new_duplicate_md5_data[GlobalConstant::UserKycDuplicationLog.only_passport_duplicate_type] << md5_obj
          new_duplicate_extended_details_id << md5_obj.user_extended_detail_id
        end





        Md5UserExtendedDetail.where(ethereum_address: @md5_user_extended_details.ethereum_address).all.each do |md5_obj|
          next if md5_obj.user_id == @user_id

          @new_duplicate_md5_data[GlobalConstant::UserKycDuplicationLog.ethereum_duplicate_type] << md5_obj
          new_duplicate_extended_details_id << md5_obj.user_extended_detail_id
        end

        Md5UserExtendedDetail.where(street_address: @md5_user_extended_details.street_address, city: @md5_user_extended_details.city, state: @md5_user_extended_details.state).all.each do |md5_obj|
          next if md5_obj.user_id == @user_id

          @new_duplicate_md5_data[GlobalConstant::UserKycDuplicationLog.address_duplicate_type] << md5_obj
          new_duplicate_extended_details_id << md5_obj.user_extended_detail_id
        end

        return {} if new_duplicate_extended_details_id.blank?

        new_duplicate_extended_details_id.uniq!
        @active_duplicate_extended_details_ids = UserKycDetail.where(user_extended_detail_id: new_duplicate_extended_details_id).pluck(:user_extended_detail_id)

      end

      def remove_inactive_md5_data
        return {} if @active_duplicate_extended_details_ids.blank?

        @new_duplicate_md5_data.each do |duplicate_type, md5_objs|
          md5_objs.each do |md5_obj|
            next if @active_duplicate_extended_details_ids.exclude?(md5_obj.user_extended_detail_id)

            @user_kyc_duplicate_log_sql_values << add_row_in_db_format(duplicate_type, md5_obj)
            @new_duplicate_user_ids << md5_obj.user_id
          end
        end

        @new_duplicate_user_ids.uniq!
      end

      def add_row_in_db_format(duplicate_type, md5_obj)
        "(#{@user_id}, #{md5_obj.user_id}, #{@md5_user_extended_details.user_extended_detail_id}, #{md5_obj.user_extended_detail_id}, #{duplication_type_int(duplicate_type)}, #{duplication_status_int}, '#{timestamp}', '#{timestamp}')"
      end

      def insert_new_dupliacte_logs
        UserKycDuplicationLog.bulk_insert(@user_kyc_duplicate_log_sql_values)
      end

      def set_duplicate_status_of_new_users
        UserKycDetail.where(user_id: @new_duplicate_user_ids).update_all(is_duplicate: GlobalConstant::UserKycDetail.true_status)
      end

      def duplication_type_int(duplicate_type)
        UserKycDuplicationLog.duplicate_types[duplicate_type]
      end

      def duplication_status_int
        @duplication_status_int ||= UserKycDuplicationLog.statuses[GlobalConstant::UserKycDuplicationLog.active_status]
      end

      def timestamp
        @timestamp ||= Time.now.to_s(:db)
      end

    end

  end

end