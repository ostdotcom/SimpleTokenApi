Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope 'api/user', controller: 'user/login' do
    match 'sign-up' => :sign_up, via: :POST
    match 'login' => :login, via: :POST
    match 'logout' => :logout, via: :POST
    match 'reset-password' => :reset_password, via: :POST
    match 'send-reset-password-link' => :send_reset_password_link, via: :POST
    match 'user-info' => :user_info, via: :GET
  end

  scope 'api/user', controller: 'user/token_sale' do
    match 'kyc-submit' => :kyc_submit, via: :POST
    match 'bt-submit' => :bt_submit, via: :POST
    match 'double-opt-in' => :double_opt_in, via: :POST
    match 'upload-params' => :get_upload_params, via: :GET
  end

  scope 'api/user', controller: 'user/profile' do
    match 'basic-detail' => :basic_detail, via: :GET
  end

  scope 'api/admin', controller: 'admin/login' do
    match 'login' => :password_auth, via: :POST
    match 'mfa' => :multifactor_auth, via: :POST
  end

  match '*permalink', to: 'application#not_found', via: :all

end

