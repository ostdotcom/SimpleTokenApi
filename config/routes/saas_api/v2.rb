scope module: :v2 do
  resources :user, path: 'users', only: [:index, :create, :show], param: :user_id do

  end

  resources 'users_kyc', path: 'users-kyc', only: [:index, :show] do
    post '/', action: :submit

    get 'pre-signed-urls/for-put', action: :get_pre_singed_url_for_put
    get 'pre-signed-urls/for-post', action: :get_pre_singed_url_for_post
  end

  resources 'users_kyc_details', path: 'users-kyc-details', only: [:show], param: :user_id

  scope 'ethereum-address-validation', controller: :validator do
    get '/', action: :validate_ethereum_address
  end

end


# http://kyc.developmentost.com:8080/api/v2/ethereum-address-validation