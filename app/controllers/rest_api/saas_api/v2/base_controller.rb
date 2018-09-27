class RestApi::SaasApi::V2::BaseController < RestApi::SaasApi::BaseController

  private

  # Get authenticator route
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def authenticator
    Authentication::ApiRequest::V2
  end

  # No formatting required
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_api_response(response_hash)
    super
  end

end