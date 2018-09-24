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

  # Sanitize and reformat Error response as per old response
  # NOT APPLICABLE for new services V2 Onwards
  #
  # * Author: Pankaj
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def reformat_as_old_response(response_hash)
    response_hash
  end

end