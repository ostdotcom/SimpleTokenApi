module Crons

  class PopulateClientUsage

    # initialize
    #
    # * Author: Aman
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [Crons::PopulateClientUsage]
    #
    def initialize(params = {})
    end

    # perform
    #
    # * Author: Aman
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # check plan usage of client and notify team if thresholds reached
    #
    def perform
      ClientPlan.where(status: GlobalConstant::ClientPlan.active_status).all.each do |client_plan|
        client = Client.get_from_memcache(client_plan.client_id)
        client_usage_obj = populate_client_usage(client)
        notify_if_needed(client, client_plan, client_usage_obj)
        return if GlobalConstant::SignalHandling.sigint_received?
      end
    end

    private

    # populate client usage obj
    #
    # * Author: Aman
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    # @return [AR] ClientUsage
    #
    def populate_client_usage(client)
      client_id = client.id
      registration_count = User.using_client_shard(client: client).where(client_id: client_id).count
      kyc_submissions_count = UserKycDetail.using_client_shard(client: client).
          where(client_id: client_id).sum(:submission_count)

      client_usage_obj = ClientUsage.find_or_initialize_by(client_id: client_id)
      client_usage_obj.registration_count = registration_count
      client_usage_obj.kyc_submissions_count = kyc_submissions_count
      client_usage_obj.save! if client_usage_obj.changed?
      client_usage_obj
    end

    # notify if client plan usage has crosssed the threshold
    #
    # * Author: Aman
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def notify_if_needed(client, client_plan, client_usage_obj)

      template_variables = {
          registration_count: client_usage_obj.registration_count,
          kyc_submissions_count: client_usage_obj.kyc_submissions_count,
          total_kyc_sumissions_plan: client_plan.kyc_submissions_count
      }

      ClientPlan::THRESHOLD_PERCENT.each do |notification_type, threshold_percent|
        next if ClientPlan.notification_types[client_plan.notification_type].to_i >= ClientPlan.notification_types[notification_type]
        next if client_usage_obj.kyc_submissions_count < ((client_plan.kyc_submissions_count * threshold_percent) / 100.0)
        send_report_email(template_variables.merge(client_name: client.name, threshold_percent: threshold_percent))
        client_plan.notification_type = notification_type
      end

      client_plan.save! if client_plan.changed?
    end

    # send email to kyc team for billing plan upgrade
    #
    # * Author: Aman
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def send_report_email(template_variables)

     admin_emails = GlobalConstant::Admin.get_all_admin_emails_for(
          client_plan.client_id,
          GlobalConstant::Admin.billing_plan_notification_notification_type
      )

      (admin_emails + GlobalConstant::Email.default_billing_to).each do |to_email|
        Email::HookCreator::SendTransactionalMail.new(
            client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
            email: to_email,
            template_name: GlobalConstant::PepoCampaigns.billing_plan_notification_template,
            template_vars: template_variables
        ).perform
      end
    end


  end

end