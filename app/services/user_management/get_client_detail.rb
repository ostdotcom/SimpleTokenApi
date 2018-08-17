module UserManagement

  class GetClientDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [String] template_type (mandatory) - this is the page template name
    # @params [boolean] in_preview_mode (optional) - this is to open urls in preview mode
    # @params [Integer] gid (optional) - this is to open urls in preview mode for some group id
    #
    # @return [UserManagement::GetClientDetail]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @entity_type = @params[:template_type]
      @in_preview_mode = @params[:in_preview_mode]
      @entity_group_id = (@in_preview_mode ? @params[:gid] : 0)

      @client = nil
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
      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      r = validate_client_details
      return r unless r.success?

      r = fetch_client_data_from_cache
      return r unless r.success?

      success_with_data(r.data)
    end

    private

    # validate and sanitize params data
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize
      @entity_type = @entity_type.to_s.strip

      r = validate
      return r unless r.success?

      return error_with_data(
          'um_gcd_1',
          'Invalid Template Type',
          'Invalid Template Type',
          GlobalConstant::ErrorAction.default,
          {}
      ) if allowed_entity_types.exclude?(@entity_type)

      if @in_preview_mode
        eg = EntityGroup.get_entity_group_from_memcache(@entity_group_id)
        return error_with_data(
            'um_gcd_2',
            'Invalid Entity Group in Preview mode',
            'Invalid Entity Group in Preview mode',
            GlobalConstant::ErrorAction.default,
            {}
        ) if eg.blank? || (eg.client_id != @client_id)
      end

      success
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
          'um_gbd_1',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_web_host_setup_done?

      success
    end

    # Fetch clients setting and page setting data from cache
    #
    # * Author: Aman
    # * Date: 15/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_data_from_cache
      ClientSetting.new(@client_id, @entity_type, @entity_group_id).perform
    end

    # Allowed entity types to open saas user pages
    #
    # * Author: Pankaj
    # * Date: 16/08/2018
    # * Reviewed By:
    #
    # @return [Array] - Allowed entity types
    #
    def allowed_entity_types
      if @in_preview_mode
        [
          GlobalConstant::EntityGroupDraft.theme_entity_type,
          GlobalConstant::EntityGroupDraft.registration_entity_type,
          GlobalConstant::EntityGroupDraft.kyc_entity_type,
          GlobalConstant::EntityGroupDraft.dashboard_entity_type
        ]
      else
        [
          GlobalConstant::EntityGroupDraft.login_entity_type,
          GlobalConstant::EntityGroupDraft.registration_entity_type,
          GlobalConstant::EntityGroupDraft.reset_password_entity_type,
          GlobalConstant::EntityGroupDraft.change_password_entity_type,
          GlobalConstant::EntityGroupDraft.token_sale_blocked_region_entity_type
        ]
      end
    end

  end

end