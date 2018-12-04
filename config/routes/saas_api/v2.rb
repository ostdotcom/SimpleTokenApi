scope module: :v2 do
  resources :users, path: 'users', only: [:index, :create, :show], constraints: { id: /[0-9a-z\.\-]+/i } do

  end

  resources :users_kyc, path: 'users-kyc', only: [:index, :show], param: :user_id do
    collection do
      post '/:user_id', action: :submit, constraints: { user_id: /[0-9a-z\.\-]+/i }
      get 'pre-signed-urls/for-put', action: :get_pre_singed_url_for_put
      get 'pre-signed-urls/for-post', action: :get_pre_singed_url_for_post
      post 'email/approve', action: :email_kyc_approve
    end
  end

  resources :users_kyc_detail, path: 'users-kyc-detail', only: [:show], param: :user_id, constraints: { user_id: /[0-9a-z\.\-]+/i }

  scope 'ethereum-address-validation', controller: :validator do
    get '/', action: :validate_ethereum_address
  end

end

