class Callback::BaseController < ApiController

  skip_before_action :authenticate_request

end