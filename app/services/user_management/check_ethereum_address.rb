module UserManagement

  class CheckEthereumAddress < ServicesBase

    # Initialize
    #
    # * Author: Abhay
    # * Date: 31/10/2017
    # * Reviewed By: Sunil
    #
    # @param [String] ethereum_address (mandatory)
    #
    # @return [UserManagement::CheckEthereumBalance]
    #
    # Sets @ethereum_address
    #
    def initialize(params)
      super

      @ethereum_address = @params[:ethereum_address]
    end

    # Perform
    #
    # * Author: Abhay
    # * Date: 31/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = make_api_call_and_validate_ethereum_address
      return r unless r.success?

      success
    end

    private

    # Validate and Sanitize
    #
    # * Author: Abhay
    # * Date: 31/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      @ethereum_address = Util::CommonValidator.sanitize_ethereum_address(@ethereum_address)

      unless Util::CommonValidator.is_ethereum_address?(@ethereum_address)
        # IF error, return
        return error_with_data(
            'um_cea_1',
            '',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            {ethereum_address: 'Invalid ethereum address.'}
        )
      end

      success
    end

    # Make API Call and validate ethereum address
    #
    # * Author: Abhay
    # * Date: 31/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def make_api_call_and_validate_ethereum_address
      r = OpsApi::Request::ValidEthereumAddress.new.perform({address: @ethereum_address})

      # web3_js_error = true is required because when API is down or any exception is raised or response is not 200
      # front end doesn't need to see invalid ethereum address
      if !r.success? && r.data[:web3_js_error]
        return error_with_data(
            'um_cea_1',
            '',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            {ethereum_address: 'Invalid Ethereum Address'}
        )
      end

      success
    end
  end

end
