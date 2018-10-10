class RestApi::SaasApi::V2::UsersKycDetailController < RestApi::SaasApi::V2::BaseController

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
    @service_response = UserManagement::KycDetail::Get.new(params).perform
    format_service_response
  end

  # Get formatter class
  #
  # * Author: Aniket
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def get_formatter_class
    Formatter::V2::UsersKycDetail
  end

end