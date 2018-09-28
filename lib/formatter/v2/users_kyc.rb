module Formatter
  module V2
    class UsersKyc
      class << self

        # Format kyc list
        # Always receives [Result::Base]
        # :NOTE Reading data to format from key:'users_kyc'
        #
        # * Author: Tejas
        # * Date: 24/09/2018
        # * Reviewed By:
        #
        # Sets result_type, users_kyc
        #
        def index(data_to_format)
          data_to_format
        end

        # Format kyc
        # Always receives [Result::Base]
        # :NOTE Reading data to format from key:'user_kyc'
        #
        # * Author: Tejas
        # * Date: 24/09/2018
        # * Reviewed By:
        #
        # Sets result_type, user_kyc
        #
        def show(data_to_format)
          result_data = data_to_format.data

          formatted_data = {
              result_type: 'user_kyc',
              user_kyc: user_kyc_base(result_data[:user_kyc_detail], result_data[:admin])
          }

          data_to_format.data = formatted_data
          data_to_format
        end


        def submit(data_to_format)
          show(data_to_format)
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
        def get_pre_singed_url_for_put(data_to_format)
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
        def get_pre_singed_url_for_post(data_to_format)
          formatted_data = {
              result_type: 'file_upload_post',
              file_upload_post: data_to_format.data

          }
          data_to_format.data = formatted_data
          data_to_format
        end

        private

        # Format Kyc
        # :NOTE Should receive user_kyc object
        #
        # * Author: Tejas
        # * Date: 24/09/2018
        # * Reviewed By:
        #
        # @returns [Hash]
        #
        def user_kyc_base(user_kyc_detail, admin)
          {
              id: user_kyc_detail[:id],
              user_kyc_detail_id: user_kyc_detail[:user_extended_detail_id],
              user_id: user_kyc_detail[:user_id],
              kyc_status: user_kyc_detail.kyc_status,
              admin_status: user_kyc_detail[:admin_status],
              aml_status: user_kyc_detail[:cynopsis_status],
              whitelist_status: user_kyc_detail[:whitelist_status],
              admin_action_types: user_kyc_detail.admin_action_types_array,
              submission_count: user_kyc_detail[:submission_count],
              last_acted_by: admin_name(user_kyc_detail.last_acted_by, admin),
              created_at: user_kyc_detail[:created_at].to_i
          }
        end

        # Get Admin Name
        #
        # * Author: Tejas
        # * Date: 24/09/2018
        # * Reviewed By:
        #
        def admin_name(last_acted_by, admin)
          last_acted_by = last_acted_by.to_i
          if (last_acted_by > 0)
            admin.name
          elsif (last_acted_by == Admin::AUTO_APPROVE_ADMIN_ID)
            GlobalConstant::Admin.auto_approved_admin_name
          else
            ''
          end
        end

      end
    end
  end
end

