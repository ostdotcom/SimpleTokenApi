scope module: :v2 do
  resources :users, path: 'users', only: [:index, :create, :show] do

  end

  resources :users_kyc, path: 'users-kyc', only: [:index, :show], param: :user_id do
    post '/', action: :submit

    get 'pre-signed-urls/for-put', action: :get_pre_singed_url_for_put, on: :collection
    get 'pre-signed-urls/for-post', action: :get_pre_singed_url_for_post, on: :collection
  end

  resources :users_kyc_details, path: 'users-kyc-details', only: [:show], param: :user_id

  scope 'ethereum-address-validation', controller: :validator do
    get '/', action: :validate_ethereum_address
  end

end

