module AdminManagement

  module Kyc

    module AdminAction

      class EmailKycIssue < AdminManagement::Kyc::AdminAction::Base

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Integer] id (mandatory)
        # @params [Hash] email_temp_vars (mandatory)
        #
        # @return [AdminManagement::Kyc::AdminAction::KycIssueEmail]
        #
        def initialize(params)
          super

          @email_temp_vars = @params[:email_temp_vars]
          @sanitized_email_data = {}
        end

        # Deny KYC by admin
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # return [Result::Base]
        #
        def perform

          r = validate_and_sanitize
          return r unless r.success?

          r = validate_for_email_setup
          return r unless r.success?

          log_admin_action

          send_email

          update_kyc_details

          enqueue_job

          success_with_data(@api_response_data)
        end

        private

        # Validate & sanitize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # Sets @sanitized_email_data
        #
        # return [Result::Base]
        #
        def validate_and_sanitize

          r = super
          return r unless r.success?

          return error_with_data(
              'am_k_aa_eki_1',
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
                'am_k_aa_eki_2',
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
              'am_k_aa_eki_3',
              'NO option selected for kyc issue',
              'Please mention the reason to email issue',
              GlobalConstant::ErrorAction.default,
              {},
              {}
          ) unless @sanitized_email_data.present?

          return error_with_data(
              'am_k_aa_eki_4',
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
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        def send_email

          Email::HookCreator::SendTransactionalMail.new(
              client_id: @client.id,
              email: @user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_issue_template,
              template_vars: @sanitized_email_data
          ).perform

        end

        # Update Kyc Details
        #
        # * Author: Aman
        # * Date: 25/10/2017
        # * Reviewed By:
        #
        def update_kyc_details
          @email_temp_vars.each do |issue_category, issue|
            @user_kyc_detail.send("set_" + issue_category.to_s) if issue.present?
          end

          @user_kyc_detail.last_acted_by = @admin_id
          @user_kyc_detail.last_acted_timestamp = Time.now.to_i
          @user_kyc_detail.save! if @user_kyc_detail.changed?
        end

        # user action log table action name
        #
        # * Author: Aman
        # * Date: 21/10/2017
        # * Reviewed By: Sunil
        #
        def logging_action_type
          GlobalConstant::UserActivityLog.kyc_issue_email_sent_action
        end

        # Do remaining task in sidekiq
        #
        # * Author: Tejas
        # * Date: 16/10/2018
        # * Reviewed By:
        #
        def enqueue_job
          BgJob.enqueue(
              WebhookJob::RecordEvent,
              {
                  client_id: @user_kyc_detail.client_id,
                  event_source: GlobalConstant::Event.web_source,
                  event_name: GlobalConstant::Event.kyc_status_update_name,
                  event_data: {
                      user_kyc_detail: @user_kyc_detail.get_hash,
                      admin: @admin.get_hash
                  },
                  event_timestamp: Time.now.to_i
              }
          )

        end

      end

    end

  end

end
