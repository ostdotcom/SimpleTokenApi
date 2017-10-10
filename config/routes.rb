Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope '/user', controller: 'user' do
    match 'sign-up' => :sign_up, via: :POST
    match 'login' => :login, via: :POST
  end

  scope '/admin', controller: 'admin' do
    match 'login' => :password_auth, via: :POST
    match 'mfa' => :multifactor_auth, via: :POST
  end

  match '*permalink', to: 'application#not_found', via: :all

end
