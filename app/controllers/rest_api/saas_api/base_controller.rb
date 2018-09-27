class RestApi::SaasApi::BaseController < RestApi::RestApiController

  before_action :authenticate_request

  private

  # Authenticate client request by validating api credentials
  #
  # * Author: Aman
  # * Date: 27/12/2017
  # * Reviewed By:
  #TODO: add check for forbidden request if client request is not allowed for web based.
  def authenticate_request(allow_web_based_client = false)
    Rails.logger.info("allow_web_based_client-#{allow_web_based_client}")

    request_parameters = request.request_method == 'GET' ? request.query_parameters : request.request_parameters

    service_response = authenticator.new(
        params.merge({
                         request_parameters: request_parameters,
                         url_path: request.path,
                         allow_web_based_client: allow_web_based_client
                     })
    ).perform

    if service_response.success?
      # Set client id
      params[:client_id] = service_response.data[:client_id]

      # Remove sensitive data
      service_response.data = {}
    else
      render_api_response(service_response)
    end
  end

  def authenticator
    fail "Method override missing"
  end

end