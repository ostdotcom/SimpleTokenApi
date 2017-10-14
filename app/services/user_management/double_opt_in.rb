module UserManagement

  class DoubleOptIn < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @params [String] t (mandatory)
    #
    # @return [UserManagement::DoubleOptIn]
    #
    def initialize(params)
      super
      @t = @params[:t]
      @user_id = @params[:user_id]
    end

    # Perform
    #
    # * Author: Puneet
    # * Date: 13/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      r = fetch_user_data
      return r unless r.success?

      return success if @user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")

      r = fetch_token_sale_double_opt_in_token
      return r unless r.success?

      r = mark_token_as_used
      # r is returned as error if token was marked used in some other concurrent request
      # And we return success to user in this case
      return success unless r.success?

      save_user

      enqueue_job

      success

    end

    # Validate
    #
    # * Author: Puneet
    # * Date: 13/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def validate

      r = super
      return r unless r.success?

      splited_t = @t.split(':')

      return invalid_url_error('um_doi_1') if splited_t.length != 2

      @token = splited_t[1]

      @token_sale_double_opt_in_token_id = splited_t[0].to_i

      success

    end

    # Fetch user data
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Kedar
    #
    # Sets @user, @user_secret
    #
    def fetch_user_data
      #TODO: Cache this query
      @user = User.where(id: @user_id).first
      success
    end

    # Fetch DB row containing token info
    #
    # * Author: Puneet
    # * Date: 13/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def fetch_token_sale_double_opt_in_token

      @token_sale_double_opt_in_token = TemporaryToken.where(id: @token_sale_double_opt_in_token_id).first

      return invalid_url_error('um_doi_2') if @token_sale_double_opt_in_token.blank?

      return invalid_url_error('um_doi_3') if @token_sale_double_opt_in_token.token != @token

      if @token_sale_double_opt_in_token.status != GlobalConstant::TemporaryToken.active_status
        return invalid_url_error('um_doi_4')
      end

      if @token_sale_double_opt_in_token.user_id != @user_id
        return invalid_url_error('um_doi_5')
      end

      if @token_sale_double_opt_in_token.kind != GlobalConstant::TemporaryToken.double_opt_in_kind
        return invalid_url_error('um_doi_6')
      end

      success

    end

    # Mark Token as Used
    #
    # * Author: Puneet
    # * Date: 13/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def mark_token_as_used
      row_updated_count = TemporaryToken.where(
        id: @token_sale_double_opt_in_token.id,
        status: GlobalConstant::TemporaryToken.active_status
      ).update_all(status: GlobalConstant::TemporaryToken.used_status)

      # if row_updated_count == 0 means this token was already marked as used by some other concurrent request
      row_updated_count > 0 ? success : invalid_url_error('um_doi_7')
    end

    # Save User
    #
    # * Author: Puneet
    # * Date: 13/10/2017
    # * Reviewed By: Kedar
    #
    def save_user
      @user.send("set_#{GlobalConstant::User.token_sale_double_optin_done_property}")
      @user.save!
    end

    # Enqueue Job
    #
    # * Author: Puneet
    # * Date: 13/10/2017
    # * Reviewed By: Kedar
    #
    def enqueue_job
      BgJob.enqueue(
        KycSubmitJob,
        {
          user_id: @user_id
        }
      )
    end

    # Invalid Request Response
    #
    # * Author: Puneet
    # * Date: 13/10/2017
    #
    # @return [Result::Base]
    #
    def invalid_url_error(code)
      error_with_data(
        code,
        'Invalid URL',
        'Invalid URL',
        GlobalConstant::ErrorAction.default,
        {}
      )
    end

  end

end
