class UserController < ApiController

  before_action :validate_cookie, except: [
    :sign_up,
    :login
  ]
  def sign_up
    render_api_response(Result::Base.success(data: {}))
  end

  def login

  end

  def password_change

  end

  def submit_kyc

  end

  private

end
