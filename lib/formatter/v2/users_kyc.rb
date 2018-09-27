module Formatter
  module V2
    class UsersKyc
      class << self

        # Format pre signed url for put
        # Always receives [Result::Base]
        # :NOTE Reading data to format from key:'file_upload_put'
        #
        # * Author: Aniket
        # * Date: 20/09/2018
        # * Reviewed By:
        #
        # @Sets result_type, file_upload_put
        #
        def format_get_pre_singed_url_for_put(data_to_format)
          formatted_data = {
              result_type: 'file_upload_put',
              file_upload_put: data_to_format.data

          }
          data_to_format.data = formatted_data
          data_to_format
        end

        # Format pre signed url for put
        # Always receives [Result::Base]
        # :NOTE Reading data to format from key:'file_upload_put'
        #
        # * Author: Aniket
        # * Date: 20/09/2018
        # * Reviewed By:
        #
        # @Sets result_type, file_upload_put
        #
        def format_get_pre_singed_url_for_post(data_to_format)
          formatted_data = {
              result_type: 'file_upload_post',
              file_upload_post: data_to_format.data

          }
          data_to_format.data = formatted_data
          data_to_format
        end

      end
    end
  end
end
