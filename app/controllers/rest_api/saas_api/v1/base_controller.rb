class RestApi::SaasApi::V1::BaseController < RestApi::SaasApi::BaseController

  private

  # Get authenticator route
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def authenticator
    Authentication::ApiRequest::V1
  end

  # Sanitize and reformat Error response as per old response
  # NOT APPLICABLE for new services V2 Onwards
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_api_response(response_hash)
    reformat_as_old_response(response_hash)
  end

end