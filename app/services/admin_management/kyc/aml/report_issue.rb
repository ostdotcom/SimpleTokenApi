module AdminManagement

  module Kyc

    module Aml

      class ReportIssue < Base

        # Initialize
        #
        # * Author: Mayur
        # * Date: 10/1/19
        # * Reviewed By:
        #
        # @params [Hash]
        #
        # @return [AdminManagement::Kyc::Aml::ReportIssue]
        #
        def initialize(params)
          super

          @email_temp_vars = @params[:email_temp_vars]
          @sanitized_email_data = {}
        end

        # perform
        #
        # * Author: Mayur
        # * Date: 10/1/2019
        # * Reviewed By:
        #
        # return [Result::Base]
        #
        def perform

          r = validate_and_sanitize
          return r unless r.success?

          log_admin_action

          send_email

          update_kyc_details

          enqueue_job(GlobalConstant::Event.web_source)

          success_with_data(@api_response_data)
        end

        private

        # Validate & sanitize
        #
        # * Author: Mayur
        # * Date: 10/1/2019
        # * Reviewed By:
        #
        # Sets @sanitized_email_data
        #
        # return [Result::Base]
        #
        def validate_and_sanitize

          r = super
          return r unless r.success?


          r = validate_for_email_setup
          return r unless r.success?


          return error_with_data(
              'am_k_ari_vs_1',
              'Please select options for email issue',
              'Please mention the reason to email issue',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @email_temp_vars.blank?

          error_fields = {}

          @email_temp_vars.each do |issue_category, issue_data|
            issue_category = issue_category.to_s

            issue_data_enum = GlobalConstant::UserActivityLog.kyc_issue_email_sent_action_categories[issue_category]

            return error_with_data(
                'am_k_ari_vs_2',
                'Invalid option for kyc issue',
                'Invalid option for kyc issue',
                GlobalConstant::ErrorAction.default,
                {}
            ) if issue_data_enum.nil?

            next if issue_data.blank?

            if GlobalConstant::UserKycDetail.other_issue_admin_action_type == issue_category
              error_fields[issue_category] = 'please enter some description' if !issue_data.is_a?(String)
              @sanitized_email_data[issue_category] = issue_data
              @extra_data[issue_category] = issue_data
            else
              error_fields[issue_category] = 'please select some options' if !issue_data.is_a?(Array)
              invalid_subcategories = issue_data - issue_data_enum.keys
              error_fields[issue_category] = "invalid categories selected- #{invalid_subcategories.join(', ')}" if invalid_subcategories.present?

              @extra_data[issue_category] = issue_data
              @sanitized_email_data[issue_category] ||= {}
              issue_data.each do |issue|
                @sanitized_email_data[issue_category][issue.to_s] = "1"
              end
            end
          end

          return error_with_data(
              'am_k_ari_vs_3',
              'NO option selected for kyc issue',
              'Please mention the reason to email issue',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          ) unless @sanitized_email_data.present?

          return error_with_data(
              'am_k_ari_vs_4',
              'Invalid option for kyc issue',
              '',
              GlobalConstant::ErrorAction.default,
              {},
              error_fields
          ) if error_fields.present?

          success
        end

        # Send email
        #
        # * Author: Mayur
        # * Date: 10/1/2019
        # * Reviewed By:
        #
        def send_email
          Email::HookCreator::SendTransactionalMail.new(
              client_id: @client.id,
              email: @user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_issue_template,
              template_vars: @sanitized_email_data
          ).perform if @client.client_kyc_config_detail.auto_send_kyc_report_issue_email?

        end

        # Update Kyc Details
        #
        # * Author: Mayur
        # * Date: 10/1/2019
        # * Reviewed By:
        #
        def update_kyc_details
          @email_temp_vars.each do |issue_category, issue|
            @user_kyc_detail.send("set_" + issue_category.to_s) if issue.present?
          end
          @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.unprocessed_admin_status
          @user_kyc_detail.last_acted_by = @admin_id
          @user_kyc_detail.last_acted_timestamp = Time.now.to_i
          @user_kyc_detail.save! if @user_kyc_detail.changed?
        end

        # user action log table action name
        #
        # * Author: Mayur
        # * Date: 10/1/19
        # * Reviewed By:
        #
        def logging_action_type
          GlobalConstant::UserActivityLog.kyc_issue_email_sent_action
        end


        # check if client has email setup
        #
        # * Author: Mayur
        # * Date: 10/1/2019
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        # Sets @client
        #
        def validate_for_email_setup


          @client = Client.get_from_memcache(@client_id)

          return error_with_data(
              'am_k_ari_vfes_1',
              'Client has not completed email setup',
              'Client has not completed email setup',
              GlobalConstant::ErrorAction.default,
              {}
          ) unless @client.is_email_setup_done?

          success
        end

      end

    end

  end

end
