class User::TokenSaleController < User::BaseController

  # Submit KYC
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def kyc_submit
    service_response = UserManagement::KycSubmit.new(params).perform
    render_api_response(service_response)
  end

  # Submit KYC
  #
  # * Author: Kedar
  # * Date: 11/10/2017
  # * Reviewed By: Sunil
  #
  def bt_submit
    service_response = UserManagement::BtSubmit.new(params).perform
    render_api_response(service_response)
  end

end
