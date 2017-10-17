module UserManagement

  class ProfileDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @params [Integer] user_id (mandatory) - this is the user id
    # @params [String] t (mandatory) - this is the double opt in token
    #
    # @return [UserManagement::GetBasicDetail]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]
      @token = @params[:t]

      @user = nil
      @user_token_sale_state = nil
      @user_kyc_detail = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform
      r = validate
      return r unless r.success?

      fetch_user

      r = validate_token
      return r unless r.success?

      r = validate_user_token_sale_state
      return r unless r.success?

      fetch_user_kyc_detail

      success_with_data(success_response_data)
    end

    private


    # Fetch User
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user, @user_token_sale_state
    #
    def fetch_user
      @user = User.where(id: @user_id).first
      @user_token_sale_state = @user.get_token_sale_state_page_name
    end

    # Validate token
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_token
      return success if @token.blank? || @user_token_sale_state == GlobalConstant::User.get_token_sale_state_page_names("profile_page")

      service_response = UserManagement::DoubleOptIn.new(double_opt_in_params).perform
      return unauthorized_access_response('um_pd_2') unless service_response.success?

      @user.reload
      @user_token_sale_state = @user.get_token_sale_state_page_name

      success
    end

    # Double opt in parameters
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def double_opt_in_params
      {
          user_id: @user.id,
          t: @token
      }
    end

    # Validate token
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_user_token_sale_state
      return unauthorized_access_response('um_pd_3') if @user_token_sale_state != GlobalConstant::User.get_token_sale_state_page_names("profile_page")
      success
    end

    # Fetch User Kyc Detail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user
    #
    def fetch_user_kyc_detail
      @user_kyc_detail = UserKycDetail.where(user_id: @user_id).first
    end

    # Success response data
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] final success data
    #
    def success_response_data
      {
          user: user_data,
          user_kyc_data: user_kyc_data,
          token_sale_active_status: GlobalConstant::TokenSale.st_token_sale_active_status,
          foundation_ethereum_address: get_foundation_ethereum_address
      }
    end

    # get foundation ethereum address
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [String]
    #
    def get_foundation_ethereum_address
      current_time = Time.now
      if @user_kyc_detail.kyc_approved? &&
          GlobalConstant::TokenSale.st_token_sale_active_status &&
          current_time >= GlobalConstant::TokenSale.pre_sale_start_date &&
          current_time <= GlobalConstant::TokenSale.public_sale_end_date
        GlobalConstant::TokenSale.st_foundation_ethereum_address
      else
        ''
      end
    end

    # User detail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] hash of user data
    #
    def user_data
      {
          id: @user.id,
          email: @user.email,
          bt_name: @user.bt_name,
          user_token_sale_state: @user_token_sale_state
      }
    end

    # User detail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] hash of user data
    #
    def user_kyc_data
      @user_kyc_detail.present? ?
          {
              user_id: @user.id,
              kyc_status: kyc_status,
              token_sale_participation_phase: token_sale_participation_phase
          }
          :
          {
              user_id: @user.id,
              kyc_status: GlobalConstant::UserKycDetail.kyc_pending_status,
              token_sale_participation_phase: GlobalConstant::TokenSale.token_sale_phase_for(Time.now)
          }
    end

    # User type for token sale
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [String] token sale participation phase
    #
    def token_sale_participation_phase
      @user_kyc_detail.token_sale_participation_phase
    end

    # User Kyc Status
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [String] status of kyc
    #
    def kyc_status
      case true
        when @user_kyc_detail.kyc_approved?
          GlobalConstant::UserKycDetail.kyc_approved_status
        when @user_kyc_detail.kyc_denied?
          GlobalConstant::UserKycDetail.kyc_denied_status
        when @user_kyc_detail.kyc_pending?
          GlobalConstant::UserKycDetail.kyc_pending_status
        else
          fail "Invalid kyc status"
      end
    end

    # Unauthorized access response
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def unauthorized_access_response(err, display_text = 'Unauthorized access.')
      error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {},
          {user_token_sale_state: @user_token_sale_state}
      )
    end

  end

end