scope 'kyc', controller: 'v1/kyc' do
  match 'add-kyc' => :add_kyc, via: :POST
  match 'upload-params' => :get_upload_params, via: :GET
  match 'get-file-upload-urls' => :get_s3_upload_urls, via: :GET
  match 'check-ethereum-address' => :check_ethereum_address, via: :GET
  match 'get-detail' => :get_detail, via: :GET
end

# used by fetch published version and no fetch will get from production environment
if !Rails.env.production?
  scope 'setting', controller: 'v1/setting' do
    match 'configurator/get-published-draft' => :get_published_drafts, via: :GET
  end
end