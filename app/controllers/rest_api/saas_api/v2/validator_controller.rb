class RestApi::SaasApi::V2::ValidatorController < RestApi::SaasApi::V2::BaseController

  skip_before_action :authenticate_request, only: [:validate_ethereum_address]

  before_action only: [:validate_ethereum_address] do
    authenticate_request(true)
  end

  # Check if ethereum address is valid
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def validate_ethereum_address
    @service_response = UserManagement::CheckEthereumAddress.new(params).perform
    format_service_response
  end

  # Get formatter class
  #
  # * Author: Aniket
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def get_formatter_class
    Formatter::V2::Validator
  end

end