module UserManagement
  module ContactUsPipeDrive

    class Kyc < Base

      # Initialize
      #
      # @params [String] full_name (mandatory) - full name
      # @params [String] company (mandatory) - company
      # @params [Integer] email (mandatory) - email
      # @params [Date] token_sale_start_date (mandatory) - token sale start date
      # @params [Date] token_sale_end_date (mandatory) - token sale end date
      # @params [Boolean] need_front_end (mandatory) - Need a custom front end
      # @params [Integer] applicant_volume (mandatory) - Applicant volume
      # @params [String] project_description (mandatory) - Project description
      #
      # @return [UserManagement::ContactUsPipeDrive::Kyc]
      #
      def initialize(params)
        super
      end

      # Perform
      #
      # @return [Result::Base]
      #
      def perform
        super
      end

    end
  end
end
