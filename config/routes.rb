Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  constraints(InitSimpleToken) do
    scope 'api/sale', controller: 'user/token_sale' do
      match 'details' => :sale_details, via: :GET
    end

    scope 'api/home', controller: 'user/home' do
      match 'contact-us-partners' => :contact_us_partners, via: :POST
    end

    match '*permalink', to: 'application#not_found', via: :all
  end

  constraints(InitTokenSale) do
    scope 'api/sale', controller: 'user/token_sale' do
      match 'details' => :sale_details, via: :GET
    end

    scope 'api/user', controller: 'saas_user/token_sale' do
      match 'bt-submit' => :bt_submit, via: :POST
      # match 'resend-double-opt-in' => :resend_double_opt_in, via: :GET
      match 'check-ethereum-balance' => :check_ethereum_balance, via: :GET
    end

  end

  constraints(InitKyc) do

    scope 'api/v1/kyc', controller: 'saas_api/kyc' do
      match 'add-kyc' => :add_kyc, via: :POST
      match 'upload-params' => :get_upload_params, via: :GET
      match 'check-ethereum-address' => :check_ethereum_address, via: :GET
    end

    scope 'api/admin', controller: 'admin/login' do
      match 'login' => :password_auth, via: :POST
      match 'get-ga-url' => :get_ga_url, via: :GET
      match 'mfa' => :multifactor_auth, via: :POST
    end

    scope 'api/admin/profile', controller: 'admin/profile' do
      match 'change-password' => :change_password, via: :POST
      match 'detail' => :get_detail, via: :GET
    end

    scope 'api/admin/kyc', controller: 'admin/kyc' do
      # match 'run-pos-bonus-process' => :run_pos_bonus_process, via: :GET
      # match 'run-alt-token-bonus-process' => :run_alt_token_bonus_process, via: :GET
      match 'check-details' => :check_details, via: :GET
      match 'dashboard' => :dashboard, via: :GET
      match 'fetch-duplicate' => :fetch_duplicate, via: :GET
      match 'deny-kyc' => :deny_kyc, via: :POST
      match 'data-mismatch' => :data_mismatch, via: :POST
      match 'document-id-issue' => :document_id_issue, via: :POST
      match 'selfie-img-issue' => :selfie_image_issue, via: :POST
      match 'residency-img-issue' => :residency_image_issue, via: :POST
      match 'qualify' => :qualify, via: :POST
      match 'kyc-action-logs' => :kyc_action_logs, via: :GET
      match 'whitelist-dashboard' => :whitelist_dashboard, via: :GET
      # match 'sale-daily-dashboard' => :sale_daily_dashboard, via: :GET
      # match 'sale-all-dashboard' => :sale_all_dashboard, via: :GET
      # match 'contract-events-dashboard' => :contract_events_dashboard, via: :GET
      match 'get-cases-by-email' => :get_cases_by_email, via: :GET
      match 'change-address-and-open-case' => :change_address_and_open_case, via: :POST
    end

    scope 'api/home', controller: 'user/home' do
      match 'contact-us-kyc' => :contact_us_kyc, via: :POST
    end

    scope 'api/callback', controller: 'callback/ops' do
      match 'whitelist-event' => :whitelist_event, via: :GET
    end

    match '*permalink', to: 'application#not_found', via: :all
  end


  scope 'api/user', controller: 'saas_user/login' do
    match 'sign-up' => :sign_up, via: :POST
    match 'login' => :login, via: :POST
    match 'reset-password' => :reset_password, via: :POST
    match 'send-reset-password-link' => :send_reset_password_link, via: :POST
  end

  scope 'api/user', controller: 'saas_user/token_sale' do
    match 'kyc-submit' => :kyc_submit, via: :POST
    match 'upload-params' => :get_upload_params, via: :GET
    match 'check-ethereum-address' => :check_ethereum_address, via: :GET
  end

  scope 'api/user', controller: 'saas_user/profile' do
    match 'client-detail' => :client_detail, via: :GET
    match 'basic-detail' => :basic_detail, via: :GET
    match 'profile' => :profile, via: :GET
    match 'get-token-sale-address' => :get_token_sale_address, via: :GET
  end


  match '*permalink', to: 'application#not_found', via: :all

end

