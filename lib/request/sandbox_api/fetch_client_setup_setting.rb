module Request
  module SandboxApi

    class FetchClientSetupSetting < Request::SandboxApi::Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 12/11/2018
      # * Reviewed By:
      #
      # @return [Request::SandboxApi::FetchClientSetupSetting]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 12/11/2018
      # * Reviewed By:
      #
      # @param [String] address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(environment, params)
        send_request_of_type(environment,
                             'post',
                             '/api/sandbox-env/account-setup-details',
                             params)
      end

    end
  end
end
