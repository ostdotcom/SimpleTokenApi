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

  # logout
  #
  # * Author: Aman
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def logout
    # Clear cookie
    cookies.delete(GlobalConstant::Cookie.user_cookie_name.to_sym, domain: :all)
    r = Result::Base.success({})
    render_api_response(r)
  end

end
