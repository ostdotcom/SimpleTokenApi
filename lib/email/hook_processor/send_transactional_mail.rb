module Email

  module HookProcessor

    class SendTransactionalMail < Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @param [EmailServiceApiCallHook] hook (mandatory) - db record of EmailServiceApiCallHook table
      #
      # @return [Email::HookProcessor::SendTransactionalMail] returns an object of Email::HookProcessor::SendTransactionalMail class
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform
        super
      end

      private

      # Validate
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def validate
        success
      end

      # Start processing hook
      #
      # * Author: Puneet
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def process_hook

        send_mail_params = @hook.params

        send_mail_response = pepo_campaign_obj.send_transactional_email(
          @hook.email,
          send_mail_params[:template_name],
          send_mail_params[:template_vars].merge({environment: Rails.env})
        )

        if send_mail_response['error'].present?
          error_with_data(
            'e_hp_stm_1',
            'API Call to Send Email Failed',
            'e_hp_stm_1',
            'API Call to Send Email Failed',
            send_mail_response
          )
        else
          success_with_data(send_mail_response)
        end

      end

    end

  end

end
