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

  # Format response got from service.
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_service_response
    formatted_response = @service_response
    puts "\nInside : format_service_response : #{formatted_response.inspect}"

    if formatted_response.success?
      formatted_response = get_formatter_class.send(params['action'], formatted_response)
    end

    puts "\nFinal formatted response : #{formatted_response.inspect}"
    render_api_response(formatted_response) and return
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