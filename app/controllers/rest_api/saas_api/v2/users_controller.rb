class RestApi::SaasApi::V2::UsersController < RestApi::SaasApi::V2::BaseController

  before_action :authenticate_request, only: [:create]

  before_action except: [:create] do
    authenticate_request(true)
  end

  # Get list of users by pagination
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def index
    @service_response = UserManagement::Users::List.new(params).perform
    format_service_response
  end

  # Create user
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def create
    @service_response = UserManagement::Users::Create.new(params).perform
    format_service_response
  end

  # Get user for user_id
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def show
    @service_response = UserManagement::Users::Get.new(params).perform
    format_service_response
  end

  # Get formatter class
  #
  # * Author: Aniket
  # * Date: 28/09/2018
  # * Reviewed By:
  #
  def get_formatter_class
    Formatter::V2::Users
  end


end