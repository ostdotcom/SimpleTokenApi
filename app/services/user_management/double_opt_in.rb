module UserManagement

  class DoubleOptIn < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @params [String] t (mandatory)
    # @params [Integer] user_id (mandatory)
    # @param [AR] client (mandatory) - client obj
    #
    # @return [UserManagement::DoubleOptIn]
    #
    def initialize(params)
      super
      @t = @params[:t]
      @user_id = @params[:user_id]
      @client = @params[:client]

      @client_id = @client.id
    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      r = fetch_user_data
      return r unless r.success?

      return success if @user.send("#{GlobalConstant::User.doptin_done_property}?")

      r = fetch_token_sale_double_opt_in_token
      return r unless r.success?

      r = mark_token_as_used
      return success unless r.success?

      save_user

      enqueue_job

      success

    end

    # Validate
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate

      r = super
      return r unless r.success?

      decryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
      r = decryptor_obj.decrypt(@t)
      return r unless r.success?

      decripted_t = r.data[:plaintext]
      splited_t = decripted_t.split(':')

      return invalid_url_error('um_doi_1') if splited_t.length != 2

      @token = splited_t[1]

      @token_sale_double_opt_in_token_id = splited_t[0].to_i

      success

    end

    # Fetch user data
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user
    #
    def fetch_user_data
      @user = User.using_client_shard(client: @client).get_from_memcache(@user_id)
      return invalid_url_error('um_doi_2') if @user.blank?
      success
    end

    # Fetch DB row containing token info
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def fetch_token_sale_double_opt_in_token

      @token_sale_double_opt_in_token_obj = TemporaryToken.where(id: @token_sale_double_opt_in_token_id,
                                                                 client_id: @client_id).first

      return invalid_url_error('um_doi_3') if @token_sale_double_opt_in_token_obj.blank?

      return invalid_url_error('um_doi_4') if @token_sale_double_opt_in_token_obj.token != @token

      if @token_sale_double_opt_in_token_obj.status != GlobalConstant::TemporaryToken.active_status
        return invalid_url_error('um_doi_5')
      end

      if @token_sale_double_opt_in_token_obj.entity_id != @user_id
        return invalid_url_error('um_doi_6')
      end

      if @token_sale_double_opt_in_token_obj.kind != GlobalConstant::TemporaryToken.double_opt_in_kind
        return invalid_url_error('um_doi_7')
      end

      success

    end

    # Mark Token as Used
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def mark_token_as_used
      @token_sale_double_opt_in_token_obj.status = GlobalConstant::TemporaryToken.used_status
      @token_sale_double_opt_in_token_obj.save!

      TemporaryToken.where(
          client_id: @client_id,
          entity_id: @user.id,
          kind: GlobalConstant::TemporaryToken.double_opt_in_kind,
          status: GlobalConstant::TemporaryToken.active_status
      ).update_all(
          status: GlobalConstant::TemporaryToken.inactive_status
      )

      success
    end

    # Save User
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    def save_user
      @user.send("set_#{GlobalConstant::User.doptin_done_property}")
      @user.save!
    end

    # Enqueue Job
    #
    # * Author: Tejas
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    def enqueue_job
      BgJob.enqueue(
          WebhookJob::RecordEvent,
          {
              client_id: @user.client_id,
              event_source: GlobalConstant::Event.web_source,
              event_name: GlobalConstant::Event.user_dopt_in_name,
              event_data: {
                  user: @user.get_hash
              },
              event_timestamp: Time.now.to_i
          }
      )
    end

    # Invalid Request Response
    #
    # * Author: Kedar
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
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
