class RestApi::SaasApi::BaseController < RestApi::RestApiController

  before_action :authenticate_request
  before_action :merge_source_of_request

  private

  # merge into params the source of the request to be used in services for webhooks
  #
  # * Author: Aman
  # * Date: 27/12/2017
  # * Reviewed By:
  #
  def merge_source_of_request
    params.merge!(source_of_request: GlobalConstant::Event.api_source)
  end

  # Authenticate client request by validating api credentials
  #
  # * Author: Aman
  # * Date: 27/12/2017
  # * Reviewed By:
  #
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

  # Format response got from service.
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_service_response
    formatted_response = @service_response

    if formatted_response.success?
      formatted_response.data = get_formatter_class.send(params['action'], formatted_response.data.dup)
    end

    puts "\nFinal formatted response : #{formatted_response.inspect}"
    render_api_response(formatted_response)
  end


  # Get formatter class
  #
  # * Author: Aniket
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def get_formatter_class
    fail 'get_formatter_class method is not override'
  end


end