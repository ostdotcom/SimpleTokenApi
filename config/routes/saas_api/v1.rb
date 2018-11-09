scope 'kyc', controller: 'v1/kyc' do
  match 'add-kyc' => :add_kyc, via: :POST
  match 'upload-params' => :get_upload_params, via: :GET
  match 'check-ethereum-address' => :check_ethereum_address, via: :GET
  match 'get-detail' => :get_detail, via: :GET
end