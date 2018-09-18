class RestApi::SaasApi::V2::ValidatorController < ApplicationController#RestApi::SaasApi::V2::BaseController

  # Check if ethereum address is valid
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def validate_ethereum_address
    service_response = UserManagement::CheckEthereumAddress.new(params).perform
    render_api_response(service_response)
  end
end