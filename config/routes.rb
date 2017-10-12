Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope 'api/user', controller: 'user/login' do
    match 'sign-up' => :sign_up, via: :POST
    match 'login' => :login, via: :POST
    match 'user-info' => :user_info, via: :GET
  end

  scope 'api/user', controller: 'user/token_sale' do
    match 'kyc-submit' => :kyc_submit, via: :POST
    match 'bt-submit' => :bt_submit, via: :POST
    match 'upload-params' => :get_upload_params, via: :GET
  end

  scope 'api/admin', controller: 'admin/login' do
    match 'login' => :password_auth, via: :POST
    match 'mfa' => :multifactor_auth, via: :POST
  end

  match '*permalink', to: 'application#not_found', via: :all

end

