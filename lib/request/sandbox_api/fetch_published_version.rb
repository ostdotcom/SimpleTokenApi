module Request
  module SandboxApi

    class FetchPublishedVersion < Request::SandboxApi::Base

      # Initialize
      #
      # * Author: Tejas
      # * Date: 09/10/2018
      # * Reviewed By:
      #
      # @return [Request::SandboxApi::FetchPublishedVersion]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 09/10/2018
      # * Reviewed By:
      #
      # @param [String] address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(environment, params)
        send_request_of_type(environment,
                             'get',
                             '/api/sandbox-env/configurator/get-published-draft',
                             params)
      end

    end
  end
end
