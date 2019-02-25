module Formatter
  module V2
    class UsersKyc
      class << self

        # Format kyc list
        # Always receives [Hash]
        # :NOTE Reading data to format from key:'user_kyc_details'
        #
        # * Author: Aniket
        # * Date: 27/09/2018
        # * Reviewed By:
        #
        # Sets result_type, users_kyc
        #
        def index(data_to_format)
          formatted_user_list = []
          admins = data_to_format[:admins]
          data_to_format[:user_kyc_details].each do |user_kyc_detail|
            admin = admins[user_kyc_detail[:last_acted_by]]
            formatted_user_list << user_kyc_base(user_kyc_detail, admin)
          end

          formatted_data = {
              result_type: 'users_kyc',
              users_kyc: formatted_user_list,
              meta: data_to_format[:meta]
          }
          formatted_data
        end

        # Format kyc
        # Always receives [Hash]
        # :NOTE Reading data to format from key:'user_kyc'
        #
        # * Author: Tejas
        # * Date: 24/09/2018
        # * Reviewed By:
        #
        # Sets result_type, user_kyc
        #
        def show(data_to_format)
          formatted_data = {
              result_type: 'user_kyc',
              user_kyc: user_kyc_base(data_to_format[:user_kyc_detail], data_to_format[:admin])
          }

          formatted_data
        end


        def submit(data_to_format)
          show(data_to_format)
        end

        # Format pre signed url for put
        # Always receives [Hash]
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
              file_upload_put: data_to_format

          }
          formatted_data
        end

        # Format pre signed url for put
        # Always receives [Hash]
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
              file_upload_post: data_to_format

          }
          formatted_data
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
          kyc_status = ''
          admin_status = ''
          aml_status = ''

          {
              id: user_kyc_detail[:id],
              user_kyc_detail_id: user_kyc_detail[:user_extended_detail_id],
              user_id: user_kyc_detail[:user_id],
              kyc_status: user_kyc_detail[:kyc_status],
              admin_status: user_kyc_detail[:admin_status],
              aml_status: user_kyc_detail[:aml_status],
              whitelist_status: user_kyc_detail[:whitelist_status],
              admin_action_types: user_kyc_detail[:admin_action_types_array],
              submission_count: user_kyc_detail[:submission_count],
              last_acted_by: admin_name(user_kyc_detail[:last_acted_by], admin),
              created_at: user_kyc_detail[:created_at]
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
            admin[:name]
          elsif (last_acted_by == Admin::AUTO_APPROVE_ADMIN_ID)
            GlobalConstant::Admin.auto_approved_admin_name
          else
            ''
          end
        end


        # Get response for sending KYC approve email
        #
        # * Author: Mayur
        # * Date: 03/12/2018
        # * Reviewed By:
        #
        def email_kyc_approve(data_to_format)
          {}
        end

        # Get response for sending KYC deny email
        #
        # * Author: Mayur
        # * Date: 14/12/2018
        # * Reviewed By:
        #
        def email_kyc_deny(data_to_format)
          {}
        end

        # Get response for sending KYC report issue email
        #
        # * Author: Mayur
        # * Date: 14/12/2018
        # * Reviewed By:
        #
        def email_kyc_report_issue(data_to_format)
          {}
        end



      end
    end
  end
end

