class Callback::BaseController < RestApiController

  skip_before_action :authenticate_request

end