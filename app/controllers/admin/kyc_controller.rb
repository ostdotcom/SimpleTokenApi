class Admin::KycController < Admin::BaseController

  # Check details
  #
  # * Author: Kedar
  # * Date: 14/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def check_details
    service_response = AdminManagement::Kyc::CheckDetails.new(params).perform
    render_api_response(service_response)
  end

  # Dashboard
  #
  # * Author: Kedar
  # * Date: 14/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def dashboard
    service_response = AdminManagement::Kyc::Dashboard.new(params).perform
    render_api_response(service_response)
  end

end
