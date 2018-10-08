module Formatter
  module V2
    class Users
      class << self

        # Format user list
        # Always receives [Result::Base]
        # :NOTE Reading data to format from key:'users'
        #
        # * Author: Aniket
        # * Date: 20/09/2018
        # * Reviewed By:
        #
        # @Sets result_type, users
        #
        def index(data_to_format)
          formatted_user_list = []

          result_data = data_to_format.data
          result_data[:users].each do |user|
            formatted_user_list << user_base(user)
          end

          formatted_data = {
              result_type: 'users',
              users: formatted_user_list,
              meta: result_data[:meta]
          }

          data_to_format.data = formatted_data
          data_to_format
        end

        # Format user
        # Always receives [Result::Base]
        # :NOTE Reading data to format from key:'user'
        #
        # * Author: Aniket
        # * Date: 20/09/2018
        # * Reviewed By:
        #
        # @Sets result_type, user
        #
        def show(data_to_format)
          result_data = data_to_format.data

          formatted_data = {
              result_type: 'user',
              user: user_base(result_data[:user])
          }

          data_to_format.data = formatted_data
          data_to_format
        end

        # Format user
        # Always receives [Result::Base]
        # :NOTE Reading data to format from key:'user'
        #
        # * Author: Aniket
        # * Date: 20/09/2018
        # * Reviewed By:
        #
        # @Sets result_type, user
        #
        def create(data_to_format)
          show(data_to_format)
        end

        private

        # Format user
        # :NOTE Should receive User object
        #
        # * Author: Aniket
        # * Date: 20/09/2018
        # * Reviewed By:
        #
        # @returns [Hash]
        #
        def user_base(user)
          {
              id: user[:id],
              email: user[:email],
              properties: user[:properties_array],
              created_at: user[:created_at].to_i
          }
        end

      end
    end
  end
end
