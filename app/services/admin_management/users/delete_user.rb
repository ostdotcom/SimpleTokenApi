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

        r = fetch_and_validate_admin
        return r unless r.success?

        @user = User.where(id: @user_id).first

        return error_with_data(
            'am_u_du_1',
            'User not found.',
            'User not found.',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user.nil? || @user.status == GlobalConstant::User.deactived_status

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
        @user_kyc_detail = UserKycDetail.where(user_id: @user_id).first

        return error_with_data(
            'am_u_du_2',
            'User Data is mismatch. Kyc Details not found.',
            'User Data is mismatch. Kyc Details not found.',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user.get_bits_set_for_properties.include?(GlobalConstant::User.token_sale_kyc_submitted_property) && @user_kyc_detail.nil?

        return success if @user_kyc_detail.nil?

        return error_with_data(
            'am_u_du_3',
            'Kyc Case is closed or Whitelisting is in process. Please wait for sometime.',
            'Kyc Case is closed or Whitelisting is in process. Please wait for sometime.',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) if @user_kyc_detail.case_closed_for_admin? || @user_kyc_detail.whitelist_confirmation_pending?

        success
      end

      # Deactivate User
      #
      # * Author: Pankaj
      # * Date: 18/05/2018
      # * Reviewed By:
      #
      def deactivate_user
        DeletedUser.create!(user_id: @user_id, client_id: @client_id,
                            deleted_by_admin: @admin_id, email: @user.email)

        @user.email = nil
        @user.status = GlobalConstant::User.deactived_status
        @user.save!

        if @user_kyc_detail.present?
          @user_kyc_detail.status = GlobalConstant::UserKycDetail.inactive_status
          @user_kyc_detail.save!
        end

        UserExtendedDetail.where(user_id: @user_id).update_all(updated_at: Time.now, status: GlobalConstant::User.inactive_status)
        Md5UserExtendedDetail.where(user_id: @user_id).update_all(updated_at: Time.now, status: GlobalConstant::User.inactive_status)

        success
      end

    end

  end

end