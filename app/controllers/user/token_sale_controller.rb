class User::TokenSaleController < User::BaseController

  # Sale Details
  #
  # * Author: Aman
  # * Date: 31/10/2017
  # * Reviewed By: Sunil
  #
  def sale_details
    service_response = SaleManagement::GetDetails.new(params).perform
    render_api_response(service_response)
  end

end
