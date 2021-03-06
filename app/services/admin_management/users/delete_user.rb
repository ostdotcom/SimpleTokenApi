module AdminManagement

  module Users

    class DeleteUser < ServicesBase

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 18/05/2018
      # * Reviewed By:
      #
      # @params [String] client_id (mandatory) - this is the client id
      # @params [String] admin_id (mandatory) - this is the email entered
      # @params [String] id (mandatory) - User Id which needs to be deleted
      #
      # @return [AdminManagement::Users::DeleteUser]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]
        @user_id = @params[:id]

        @user = nil
        @user_kyc_detail = nil
        @user_email_for_webhook = {}
      end

      # Perform Delete
      #
      # * Author: Pankaj
      # * Date: 18/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        r = deactivate_user
        return r unless r.success?

        enqueue_job

        success

      end

      private

      # Validate and sanitize
      #
      # * Author: Pankaj
      # * Date: 18/05/2018
      # * Reviewed By:
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        return error_with_data(
            'am_u_du_4',
            'Delete not allowed for this client.',
            'Delete not allowed for this client.',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @client.is_st_token_sale_client?

        r = fetch_and_validate_admin
        return r unless r.success?

        @user = User.using_client_shard(client: @client).where(id: @user_id).first

        return error_with_data(
            'am_u_du_1',
            'User not found.',
            'User not found.',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user.nil? || @user.status == GlobalConstant::User.deleted_status

        r = validate_user_kyc
        return r unless r.success?

        success
      end

      # Validate User kyc details
      #
      # * Author: Pankaj
      # * Date: 18/05/2018
      # * Reviewed By:
      #
      def validate_user_kyc
        @user_kyc_detail = UserKycDetail.using_client_shard(client: @client).where(user_id: @user_id).first

        return error_with_data(
            'am_u_du_2',
            'User Data is mismatch. Kyc Details not found.',
            'User Data is mismatch. Kyc Details not found.',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user.get_bits_set_for_properties.include?(GlobalConstant::User.kyc_submitted_property) && @user_kyc_detail.nil?

        return success if @user_kyc_detail.nil?

        return error_with_data(
            'am_u_du_3',
            'Kyc Case is closed.',
            'Kyc Case is closed',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user_kyc_detail.case_closed?

        success
      end

      # Deactivate User
      #
      # * Author: Pankaj
      # * Date: 18/05/2018
      # * Reviewed By:
      #
      def deactivate_user
        DeletedUser.using_client_shard(client: @client).create!(user_id: @user_id, client_id: @client_id,
                            deleted_by_admin: @admin_id, email: @user.email)

        @user_email_for_webhook = {email: @user.email}
        @user.email = nil
        @user.status = GlobalConstant::User.deleted_status
        @user.save!

        if @user_kyc_detail.present?
          if @user_kyc_detail.admin_status == GlobalConstant::UserKycDetail.qualified_admin_status
            @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.unprocessed_admin_status
          end
          @user_kyc_detail.status = GlobalConstant::UserKycDetail.inactive_status
          @user_kyc_detail.save!
        end

        success
      end

      # Enqueue job to delete Duplicates log of this user
      #
      # * Author: Pankaj
      # * Date: 18/05/2018
      # * Reviewed By:
      #
      def enqueue_job
        BgJob.enqueue(
            DeleteDuplicateLogs,
            {
                client_id: @client_id,
                user_id: @user.id,
                event: {
                    client_id: @user.client_id,
                    event_source: GlobalConstant::Event.web_source,
                    event_name: GlobalConstant::Event.user_deleted_name,
                    event_data: {
                        user: (@user.get_hash).merge!(@user_email_for_webhook)
                    },
                    event_timestamp: Time.now.to_i
                }
            }
        )
        Rails.logger.info('---- enqueue_job DeleteDuplicates done')
      end

    end

  end

end