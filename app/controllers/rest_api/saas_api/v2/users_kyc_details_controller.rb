class RestApi::SaasApi::V2::UsersKycDetailsController < RestApi::SaasApi::V2::BaseController

  skip_before_action :authenticate_request, only: [:show]

  before_action only: [:show] do
    authenticate_request(true)
  end

  # Get particular user kyc details for user_id
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def show
    puts "inside UsersKycdetailsController : show"
    service_response = UserManagement::KycDetail::Get.new(params).perform
    format_response(service_response)
  end

  # Format response got from service.
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_response(service_response)
    formatted_response = service_response
    puts "Inside : format_response"

    if service_response.success?
      formatted_response = Formatter::V2::UsersKycDetail.send(params['action'], service_response)
    end

    puts "Final formatted response : #{formatted_response.inspect}"
    render_api_response(formatted_response)
  end
end