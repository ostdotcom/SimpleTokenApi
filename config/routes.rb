Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope '/user', controller: 'user' do
    match 'test1' => :test1, via: :GET
  end

  match '*permalink', to: 'application#not_found', via: :all

end
