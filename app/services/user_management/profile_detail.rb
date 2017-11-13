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
      @user = User.get_from_memcache(@user_id)
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
      @user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)
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
          user_kyc_data: user_kyc_data
      }.merge(sale_stats)
    end

    # Sale stats
    #
    # * Author: Aman
    # * Date: 10/11/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] hash of sale stats
    #
    def sale_stats
      # can rely on check in purchase log and fetch data everytime from there ever on 14th for general access users
      PurchaseLog.sale_details
    end

    # Sale Start time for user
    #
    # * Author: Aman
    # * Date: 09/11/2017
    # * Reviewed By: Sunil
    #
    # @return [Time]
    #
    def sale_start_time_for_user
      (token_sale_participation_phase_for_user == GlobalConstant::TokenSale.early_access_token_sale_phase) ? GlobalConstant::TokenSale.early_access_start_date : GlobalConstant::TokenSale.general_access_start_date
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
              admin_action_type: @user_kyc_detail.admin_action_type,
              token_sale_participation_phase: token_sale_participation_phase_for_user,
              whitelist_status: @user_kyc_detail.whitelist_status,
              pos_bonus_percentage: @user_kyc_detail.pos_bonus_percentage,
              alternate_token_name_for_bonus: get_alternate_token_name(@user_kyc_detail.alternate_token_id_for_bonus)
          }
      :
          {
              user_id: @user.id,
              kyc_status: GlobalConstant::UserKycDetail.kyc_pending_status,
              admin_action_type: GlobalConstant::UserKycDetail.no_admin_action_type,
              token_sale_participation_phase: token_sale_participation_phase_for_user,
              whitelist_status: GlobalConstant::UserKycDetail.unprocessed_whitelist_status,
              pos_bonus_percentage: expected_pos_percentage,
              alternate_token_name_for_bonus: expected_alt_token_name_for_bonus
          }
    end

    # Pos bonus percentage for user
    #
    # * Author: Aman
    # * Date: 01/11/2017
    # * Reviewed By: Sunil
    #
    # @return [Integer] bonus percent approved for user
    #
    def expected_pos_percentage
      return nil if (GlobalConstant::TokenSale.token_sale_phase_for(Time.now) !=
          GlobalConstant::TokenSale.early_access_token_sale_phase)

      PosBonusEmail.where(email: @user.email).first.try(:bonus_percentage)

    end

    # Alternate Token name bonus for user
    #
    # * Author: Aman
    # * Date: 01/11/2017
    # * Reviewed By: Sunil
    #
    # @return [String] alternate token name bonus applied for user account
    #
    def expected_alt_token_name_for_bonus
      return nil if (GlobalConstant::TokenSale.token_sale_phase_for(Time.now) !=
          GlobalConstant::TokenSale.early_access_token_sale_phase)

      alt_t_obj = AlternateTokenBonusEmail.where(email: @user.email).first
      alt_t_obj.present? ? get_alternate_token_name(alt_t_obj.alternate_token_id) : nil
    end

    # Get token name
    #
    # * Author: Aman
    # * Date: 01/11/2017
    # * Reviewed By: Sunil
    #
    # @return [String] get alternate token name
    #
    def get_alternate_token_name(alternate_token_id)
      alternate_token_id.to_i > 0 ? AlternateToken.get_from_memcache(alternate_token_id).token_name : nil
    end

    # User type for token sale
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [String] token sale participation phase
    #
    def token_sale_participation_phase_for_user
      @token_sale_participation_phase_for_user ||= @user_kyc_detail.present? ? @user_kyc_detail.token_sale_participation_phase : GlobalConstant::TokenSale.token_sale_phase_for(Time.now)
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