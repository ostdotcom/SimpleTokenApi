class RestApi::SaasApi::V2::UserController < RestApi::SaasApi::V2::BaseController

  # before_action only: [:create] do
  #   authenticate_request(false)
  # end
  #
  # before_action except: [:create] do
  #   authenticate_request(true)
  # end

  # Get list of users by pagination
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def index
    service_response = UserManagement::Users::List.new(params).perform
    format_response(service_response)
  end

  # Create user
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def create
    service_response = UserManagement::Users::Create.new(params).perform
    format_response(service_response)
  end

  # Get user for user_id
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def show
    service_response = UserManagement::Users::Get.new(params).perform
    format_response(service_response)
  end

  # Format response got from service.
  #
  # * Author: Aniket
  # * Date: 18/09/2018
  # * Reviewed By:
  #
  def format_response(service_response)
    formatted_response = service_response
    puts "Inside : format_response"

    if service_response.success?
      case params['action'].to_sym
        when :index
          formatted_response = Formatter::V2::Users.format_user_list(service_response)

        when :show
          puts "Inside : show : #{service_response.inspect}"
          formatted_response = Formatter::V2::Users.format_user(service_response)

        when :create
          puts "Inside : create : #{service_response.inspect}"
          formatted_response = Formatter::V2::Users.format_user(service_response)

        else
          fail "Formatter for action(#{params['action']}) did not written."
      end
    end

    puts "Final formatted response : #{formatted_response.inspect}"
    render_api_response(formatted_response)
  end

end