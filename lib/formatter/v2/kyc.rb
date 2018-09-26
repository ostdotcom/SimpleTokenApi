module Formatter
  module V2
    class Kyc
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
        def format_kyc_list(data_to_format)
          formatted_user_kyc_list = []
          result_data = data_to_format.data
          result_data[:result_type] = 'users_kyc'

          users_kyc = result_data[:users_kyc]
          users_kyc.each do |user_kyc|
            formatted_user_kyc_list << user_kyc_base(user_kyc)
          end
          result_data[:users_kyc] = formatted_user_kyc_list

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
        def format_kyc(data_to_format)
          result_data = data_to_format.data
          result_data[:result_type] = 'user_kyc'

          result_data[:user_kyc] = user_kyc_base(result_data[:user_kyc_detail], result_data[:admin])

          result_data.delete(:admin)
          result_data.delete(:user_kyc_detail)

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
              user_id: user_kyc_detail[:user_id],
              kyc_status: user_kyc_detail[:status],
              admin_status: user_kyc_detail[:admin_status],
              aml_status: user_kyc_detail[:cynopsis_status],
              whitelist_status: user_kyc_detail[:whitelist_status],
              admin_action_types: user_kyc_detail.admin_action_types_array,
              submission_count: user_kyc_detail[:submission_count],
              last_acted_by: admin_name(user_kyc_detail.last_acted_by, admin),
              created_at: user_kyc_detail[:created_at].to_i
          }
        end

        def admin_name(last_acted_by, admin)
          return '' if last_acted_by.is_a?(NilClass)
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

