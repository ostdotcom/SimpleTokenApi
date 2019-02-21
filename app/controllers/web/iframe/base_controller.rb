class Web::Iframe::BaseController < Web::WebController

  before_action :authenticate_request
  before_action :authenticate_client_host


  private

  # Validate cookie
  #
  # * Author: Aman
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  def authenticate_client_host
    # check parent url of client
    # params[:client_id] = 1
  end

  # Validate cookie
  #
  # * Author: Kedar
  # * Date: 10/10/2017
  # * Reviewed By: Sunil
  #
  def authenticate_request
    # check token and get user id
    # params[:user_id] = 1
  end

end