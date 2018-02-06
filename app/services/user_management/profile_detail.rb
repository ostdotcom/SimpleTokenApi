module UserManagement

  class ProfileDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [Integer] user_id (mandatory) - this is the user id
    #
    # @return [UserManagement::GetBasicDetail]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]
      @client_id = @params[:client_id]

      @client = nil
      @client_token_sale_details = nil
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

      r = fetch_and_validate_client
      return r unless r.success?

      fetch_client_token_sale_details

      r = validate_client_details
      return r unless r.success?

      fetch_user

      r = validate_user_token_sale_state
      return r unless r.success?

      fetch_user_kyc_detail

      success_with_data(success_response_data_for_client)
    end

    private

    # Fetch token sale details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_token_sale_details
      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)
    end

    # validate clients web hosting setup details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_client_details
      return error_with_data(
          'um_su_3',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_web_host_setup_done?

      success
    end

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

    # response data on client basis
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] final success data
    #
    def success_response_data_for_client
      if @client.is_st_token_sale_client?
        {
            user: user_data_default_client,
            user_kyc_data: user_kyc_data_default_client,
            client_setting: client_setting
        }.merge(sale_stats)

      else
        {
            user: user_data,
            user_kyc_data: user_kyc_data,
            client_setting: client_setting
        }
      end
    end

    # Client Setup details
    #
    # * Author: Aman
    # * Date: 06/02/2018
    # * Reviewed By:
    #
    # @return [Hash] hash of client's kyc setting
    #
    def client_setting
      {
          is_st_token_sale_client: @client.is_st_token_sale_client?,
          is_whitelist_setup_done: @client.is_whitelist_setup_done?,
          token_sale_details: {
              sale_start_timestamp: @client_token_sale_details.sale_start_timestamp,
              sale_end_timestamp: @client_token_sale_details.sale_end_timestamp,
              has_ethereum_deposit_address: @client_token_sale_details.ethereum_deposit_address.present?
          }
      }
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
              whitelist_status: @user_kyc_detail.whitelist_status
          }
          :
          {
              user_id: @user.id,
              kyc_status: GlobalConstant::UserKycDetail.kyc_pending_status,
              admin_action_type: GlobalConstant::UserKycDetail.no_admin_action_type,
              token_sale_participation_phase: token_sale_participation_phase_for_user,
              whitelist_status: GlobalConstant::UserKycDetail.unprocessed_whitelist_status
          }
    end

    # User detail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] hash of user data for st token sale client
    #
    def user_data_default_client
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
    # @return [Hash] hash of user data for st token sale client
    #
    def user_kyc_data_default_client
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
      return nil if (token_sale_participation_phase_for_user !=
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
      return nil if (token_sale_participation_phase_for_user !=
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
      @token_sale_participation_phase_for_user ||= (@user_kyc_detail.present? ? @user_kyc_detail.token_sale_participation_phase : GlobalConstant::TokenSale.token_sale_phase_for(Time.at(@user.created_at.to_i)))
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

# send if client whitelist details and token sale details start and end time and if show deposit address
#