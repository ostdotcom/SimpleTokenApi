module UserManagement
  module ContactUs

    class Partner < Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 24/01/2018
      # * Reviewed By:
      #
      # @params [String] full_name (mandatory) - full name
      # @params [Integer] company (mandatory) - company
      # @params [Integer] email (mandatory) - email
      # @params [String] contact_number (mandatory) - contact_number
      #
      # @return [UserManagement::::ContactUs::Partner]
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 24/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        super
      end

      private

      # Subject
      #
      # * Author: Aman
      # * Date: 24/01/2018
      # * Reviewed By:
      #
      def subject
        "#{GlobalConstant::Email.subject_prefix}Partner Companies - Contact Us - #{@email}"
      end

      def send_autorespond_email

      end

      # autorespond template name
      #
      # * Author: Aman
      # * Date: 24/01/2018
      # * Reviewed By:
      #
      def autorespond_template_name
        GlobalConstant::PepoCampaigns.contact_us_ost_partner_autoresponder_template
      end

    end
  end
end
