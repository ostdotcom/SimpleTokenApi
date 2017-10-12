module UserManagement

  class BtSubmit < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @param [Integer] bt_name (mandatory) - user id
    # @param [Boolean] skip_name (mandatory) - first name
    #
    # @return [UserManagement::BtSubmit]
    #
    def initialize(params)

      super

      @bt_name = @params[:bt_name]
      @skip_name = @params[:skip_name]

      @user = nil

      @error_data = {}

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

      r = fetch_user_data
      return r unless r.success?

      r = update_user
      return r unless r.success?

      success_with_data(user_id: @user_id)
    end

    private

    # Validate
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate

      r = super
      return r unless r.success?

      @error_data[:skip_name] = "Invalid data" unless Util::CommonValidator.is_boolean?(@skip_name)

      # apply custom validations. if not skipped
      if !@skip_name
        @error_data[:bt_name] = "Branded Token Name is required." if @bt_name.blank?
        @error_data[:bt_name] = "Branded Token Name is already taken." if User.where(bt_name: @bt_name).exists?
      end

      return error_with_data(
          'um_bs_1',
          'Invalid Parameters.',
          'Invalid Parameters.',
          GlobalConstant::ErrorAction.default,
          {},
          @error_data
      ) if @error_data.present?

      success

    end

    # Fetch user data
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # Sets @user
    #
    def fetch_user_data
      @user = User.where(id: @user_id).first

      unless @user.present? && (@user.status == GlobalConstant::User.active_status)
        return unauthorized_access_response('um_bs_2')
      end

      return error_with_data(
          'um_bs_3',
          'Branded Tokens name cannot be updated',
          'Branded Tokens name cannot be updated',
          GlobalConstant::ErrorAction.default,
          {},
          {bt_name: 'Branded Tokens name cannot be updated'}
      ) if @user.properties_array.include?(GlobalConstant::User.token_sale_bt_done_property)

      success
    end


    # Update User Data
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    def update_user
      @user.set_bt_done
      @user.bt_name = @bt_name if @bt_name.present?
      @user.save!
      success
    end


    # Unauthorized access response
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @param [String] err
    # @param [String] display_text
    #
    # @return [Result::Base]
    #
    def unauthorized_access_response(err, display_text = 'Unauthorized access. Please login again.')
      error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

  end

end
