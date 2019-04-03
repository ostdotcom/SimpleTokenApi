module UserManagement
  module Users
    class Create < ServicesBase

      #
      # Initialize
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @param [AR] client (mandatory) - client obj
      # @param [String] email (mandatory) - email of user
      #
      # Sets user, new_user_added
      #
      # @return [UserManagement::Users::Create]
      #
      def initialize(params)
        super

        @client = @params[:client]
        @email = @params[:email]

        @client_id = @client.id

        @user = nil
      end


      # Perform
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        create_user

        enqueue_job

        success_with_data(service_response_data)

      end

      private

      # Validate and sanitize
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        r = validate_email
        return r unless r.success?

        r = add_user_allowed?
        return r unless r.success?

        r = fetch_and_validate_user
        return r unless r.success?

        success
      end

      # Validate email
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def validate_email
        return error_with_identifier('invalid_api_params',
                                     'um_u_c_ve_1',
                                     ['invalid_email']
        ) unless Util::CommonValidateAndSanitize.is_valid_email?(@email)

        success
      end

      # Checks whether client can add user on the basis of token_sale_end date
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      #
      def add_user_allowed?
        client_token_sale_detail = ClientTokenSaleDetail.get_from_memcache(@client_id)

        return error_with_identifier('token_sale_ended',
                                     'um_u_c_aua_1'
        ) if client_token_sale_detail.has_registration_ended?

        success
      end

      # Verify user is already present in db or not
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      # Sets user
      #
      def fetch_and_validate_user
        @user = User.using_client_shard(client: @client).where(client_id: @client_id, email: @email).is_active.first
        return error_with_identifier('invalid_api_params',
                                     'um_u_c_ve_2',
                                     ['user_already_present']
        ) if @user.present?

        success
      end

      # Create user
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def create_user
        params = {
            client_id: @client_id,
            email: @email
        }
        @user = User.using_client_shard(client: @client).create!(params)
      end

      # Do remaining task in sidekiq
      #
      # * Author: Aniket
      # * Date: 26/09/2018
      # * Reviewed By:
      #
      def enqueue_job
        BgJob.enqueue(
            NewUserRegisterJob,
            {
                client_id: @client_id,
                user_id: @user.id,
                geoip_country: nil,
                event: {
                    client_id: @user.client_id,
                    event_source: GlobalConstant::Event.api_source,
                    event_name: GlobalConstant::Event.user_register_name,
                    event_data: {
                        user: @user.get_hash
                    },
                    event_timestamp: Time.now.to_i
                }
            }
        )
      end

      # Format service response
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def service_response_data
        {
            user: @user.get_hash
        }
      end

    end
  end
end