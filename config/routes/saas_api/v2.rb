scope module: :v2 do
  resources :users, path: 'users', only: [:index, :create, :show] do

  end

  resources :users_kyc, path: 'users-kyc', only: [:index, :show], param: :user_id do
    collection do
      post '/:user_id', action: :submit
      get 'pre-signed-urls/for-put', action: :get_pre_singed_url_for_put
      get 'pre-signed-urls/for-post', action: :get_pre_singed_url_for_post
    end
  end

  resources :users_kyc_detail, path: 'users-kyc-detail', only: [:show], param: :user_id

  scope 'ethereum-address-validation', controller: :validator do
    get '/', action: :validate_ethereum_address
  end

end

