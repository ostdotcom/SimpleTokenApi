class ExternalUser::KycController < ExternalUser::BaseController

  # Add KYC
  #
  # * Author: Aman
  # * Date: 27/12/2017
  # * Reviewed By:
  #
  def add_kyc
    service_response = UserManagement::KycSubmit.new(params).perform
    render_api_response(service_response)
  end

end
