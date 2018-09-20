class RestApi::SaasApi::V2::UserController < RestApi::SaasApi::V2::BaseController

  # Get list of users by pagination
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def index
    puts "inside UserController : index"

    service_response = UserManagement::Users::List.new(params).perform
    render_api_response(service_response)
  end

  # Create user
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def create
    puts "inside UserController : create"
    puts params
  end

  # Get user details for user_id
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def show
    puts "inside UserController : show"

  end

end