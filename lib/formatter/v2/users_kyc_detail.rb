module Formatter
  module V2
    class UsersKycDetail
      class << self

        # Format kyc detail
        # Always receives [Hash]
        # :NOTE Reading data to format from key:'user_extended_detail'
        #
        # * Author: Tejas
        # * Date: 24/09/2018
        # * Reviewed By:
        #
        # Sets result_type, user_kyc_detail
        #
        def show(data_to_format)
          result_data = data_to_format.data
          formatted_data = {
              result_type: 'user_kyc_detail',
              user_kyc: kyc_detail_base(result_data[:user_extended_detail])
          }

          formatted_data
        end

        private

        # Format user kyc detail
        # :NOTE Should receive User extended details object
        #
        # * Author: Aniket
        # * Date: 20/09/2018
        # * Reviewed By:
        #
        # @returns [Hash]
        #
        def kyc_detail_base(user_extended_detail)
          user_extended_detail[:created_at] = user_extended_detail[:created_at].to_i
          user_extended_detail
        end

      end
    end
  end
end
