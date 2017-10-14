module UserManagement

  class ProfileDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @param [Integer] user_id (mandatory) - this is the user id
    # @param [String] t (mandatory) - this is the double opt in token
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
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate
      return r unless r.success?

      fetch_user

      r = validate_token
      return r unless r.success?

      fetch_user_kyc_detail

      success_with_data(success_response_data)
    end

    private


    # Fetch User
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # Sets @user
    #
    def fetch_user
      @user = User.where(id: @user_id).first
      @user_token_sale_state = @user.get_token_sale_state_page_name
    end

    # Validate token
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_token
      return success if @token.blank?

      service_response = UserManagement::DoubleOptIn.new(double_opt_in_params).perform
      return unauthorized_access_response('um_pd_2') unless service_response.success?
      @user.reload
      success
    end

    def double_opt_in_params
      {
          user_id: @user.id,
          t: @token
      }
    end

    # Fetch User Kyc Detail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # Sets @user
    #
    def fetch_user_kyc_detail
      @user_kyc_detail = UserKycDetail.where(user_id: @user_id).first
    end

    # User detail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
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
    # * Reviewed By:
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

    # User Kyc Status
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
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

    # User type for token sale
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @return [String] token sale participation phase
    #
    def token_sale_participation_phase
      @user_kyc_detail.token_sale_participation_phase
    end

    # Unauthorized access response
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
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

    def success_response_data
      {
          user: user_data,
          user_kyc_data: user_kyc_data,
          token_sale_active_status: GlobalConstant::TokenSale.st_token_sale_active_status
      }
    end

  end

end