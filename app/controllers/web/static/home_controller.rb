class Web::Static::HomeController < Web::Static::BaseController

  before_action :verify_recaptcha

  #
  # * Author: Aman
  # * Date: 18/01/2018
  # * Reviewed By:
  #
  def contact_us_partners
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
