class Web::Admin::UserController < Web::Admin::BaseController

  before_action {authenticate_request(true)}

  # Get users list
  #
  # * Author: Pankaj
  # * Date: 15/05/2018
  # * Reviewed By:
  #
  def get_users_list
    service_response = AdminManagement::Users::UserList.new(params).perform
    render_api_response(service_response)
  end



end