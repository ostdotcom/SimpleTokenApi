class User::LoginController < ApiController

  before_action :validate_cookie, except: [
    :sign_up,
    :login
  ]

  def sign_up

  end

  def login

  end

end
