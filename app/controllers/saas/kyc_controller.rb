class Saas::KycController < Saas::BaseController

  # Add KYC
  #
  # * Author: Aman
  # * Date: 27/12/2017
  # * Reviewed By:
  #
  def add_kyc
    service_response = SaasManagement::AddUser.new(client_id: params[:client_id], email: params[:email]).perform

    if service_response.success?
      service_response = UserManagement::KycSubmit.new(params.merge(user_id: service_response.data[:user_id])).perform
    end

    render_api_response(service_response)
  end

end
