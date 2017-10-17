class User::ProfileController < User::BaseController

  # Get logged in user details
  #
  # * Author: Aman
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def basic_detail
    service_response = UserManagement::GetBasicDetail.new(params).perform
    render_api_response(service_response)
  end

  # Get profile info and validate double opt in token if present
  #
  # * Author: Aman
  # * Date: 13/10/2017
  # * Reviewed By: Sunil
  #
  def profile
    service_response = UserManagement::ProfileDetail.new(params).perform
    render_api_response(service_response)
  end

end
