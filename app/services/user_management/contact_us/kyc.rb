module UserManagement
  module ContactUs

    class Kyc < Base

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
      # @return [UserManagement::::ContactUs::Kyc]
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
        "#{GlobalConstant::Email.subject_prefix}ostKYC Lead - Contact Us - #{@email}"
      end

    end
  end
end
