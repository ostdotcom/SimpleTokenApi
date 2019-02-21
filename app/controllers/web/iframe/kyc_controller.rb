class Web::Iframe::KycController < Web::Iframe::BaseController

  # Get user details with tokens
  #
  # * Author: Aman
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def basic_detail
    # use a diff service
    service_response = UserManagement::GetBasicDetail.new(params).perform
    render_api_response(service_response)
  end

end
