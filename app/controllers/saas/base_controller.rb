class Saas::BaseController < RestApiController

  private

  # Authenticate client request by validating api credentials
  #
  # * Author: Aman
  # * Date: 27/12/2017
  # * Reviewed By:
  #
  def authenticate_request
    service_response = ClientManagement::VerifyApiCredential.new(
        params.merge({
                         request_parameters: request.request_parameters,
                         url_path: request.path
                     })
    ).perform

    if service_response.success?
      # Set client id
      params[:client_id] = service_response.data[:client_id]

      # Remove sensitive data
      service_response.data = {}
    else
      # Set 401 header
      service_response.http_code = GlobalConstant::ErrorCode.unauthorized_access
      render_api_response(service_response)
    end
  end

end