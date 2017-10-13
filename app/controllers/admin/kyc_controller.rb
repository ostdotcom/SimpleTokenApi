class Admin::KycController < Admin::BaseController

  # Check details
  #
  # * Author: Kedar
  # * Date: 14/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def check_details
    service_response = AdminManagement::Kyc::CheckDetails.new(params)
    render_api_response(service_response)
  end

end
