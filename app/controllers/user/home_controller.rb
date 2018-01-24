class User::HomeController < User::BaseController

  skip_before_action :authenticate_request

  #
  # * Author: Aman
  # * Date: 18/01/2018
  # * Reviewed By:
  #
  def contact_us_partner
    service_response = UserManagement::ContactUs::Partner.new(params).perform
    render_api_response(service_response)
  end

  #
  # * Author: Aman
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def contact_us_kyc
    service_response = UserManagement::ContactUs::Kyc.new(params).perform
    render_api_response(service_response)
  end

end
