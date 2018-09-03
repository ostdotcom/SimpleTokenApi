Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  constraints(InitStaticOst) do

    scope 'api/home', controller: 'web/static/home' do
      match '/partners/contact-us' => :contact_us_partners_pipe_drive, via: [:GET, :POST]
    end

    scope 'api/home/alpha', controller: 'web/static/home' do
      match '/4/signup' => :register_for_alpha4, via: [:GET, :POST]
    end

    match '*permalink', to: 'application#not_found', via: :all
  end

  constraints(InitSimpleToken) do
    scope 'api/sale', controller: 'web/static/token_sale' do
      match 'details' => :sale_details, via: :GET
    end

    match '*permalink', to: 'application#not_found', via: :all
  end

  constraints(InitTokenSale) do
    scope 'api/sale', controller: 'web/static/token_sale' do
      match 'details' => :sale_details, via: :GET
    end

    scope 'api/user', controller: 'web/saas_user/token_sale' do
      match 'bt-submit' => :bt_submit, via: :POST
      match 'check-ethereum-balance' => :check_ethereum_balance, via: :GET
    end

  end

  constraints(InitKyc) do

    scope 'api/v1/kyc', controller: 'rest_api/saas_api/kyc' do
      match 'add-kyc' => :add_kyc, via: :POST
      match 'upload-params' => :get_upload_params, via: :GET
      match 'check-ethereum-address' => :check_ethereum_address, via: :GET
      match 'get-detail' => :get_detail, via: :GET
    end

    scope 'api/admin', controller: 'web/admin/login' do
      match 'login' => :password_auth, via: :POST
      match 'get-ga-url' => :get_ga_url, via: :GET
      match 'mfa' => :multifactor_auth, via: :POST
      match 'reset-password' => :admin_reset_password, via: :POST
      match 'send-reset-password-link' => :send_admin_reset_password_link, via: :POST
      match 'invite-detail' => :invite_detail, via: :GET
      match 'activate-invite' => :activate_invited_admin, via: :POST
    end

    scope 'api/admin/profile', controller: 'web/admin/profile' do
      match 'change-password' => :change_password, via: :POST
      match 'detail' => :get_detail, via: :GET
    end

    scope 'api/admin/client', controller: 'web/admin/client' do
      match 'profile' => :get_profile_detail, via: :GET
      match 'developer-details' => :get_developer_detail, via: :GET
      match 'auto-approve-setting' => :get_auto_approve_setting, via: :GET
      match 'get-sale-setting' => :get_sale_setting, via: :GET
      match 'get-country-setting' => :get_country_setting, via: :GET
    end

    scope 'api/admin/kyc', controller: 'web/admin/kyc' do
      # match 'change-address-and-open-case' => :change_address_and_open_case, via: :POST

      # match 'run-pos-bonus-process' => :run_pos_bonus_process, via: :GET
      # match 'run-alt-token-bonus-process' => :run_alt_token_bonus_process, via: :GET
      match 'check-details' => :check_details, via: :GET
      match 'fetch-duplicate' => :fetch_duplicate, via: :GET
      match 'kyc-action-logs' => :kyc_action_logs, via: :GET
      # match 'whitelist-dashboard' => :whitelist_dashboard, via: :GET
      # match 'sale-daily-dashboard' => :sale_daily_dashboard, via: :GET
      # match 'sale-all-dashboard' => :sale_all_dashboard, via: :GET
      # match 'contract-events-dashboard' => :contract_events_dashboard, via: :GET

      match 'deny-kyc' => :deny_kyc, via: :POST
      match 'email-kyc-issue' => :email_kyc_issue, via: :POST
      match 'qualify' => :qualify, via: :POST

      match 'get-cases-by-email' => :get_cases_by_email, via: [:GET, :POST]
      match 'retry-cynopsis-upload' => :retry_cynopsis_upload, via: :POST
      match 'dashboard' => :dashboard, via: :GET

      match 'open-case' => :open_kyc_case, via: :POST
      match 'update-address' => :update_ethereum_address, via: :POST
    end

    scope 'api/admin/kyc', controller: 'web/admin/super_admin' do
      match 'get-kyc-report' => :get_kyc_report, via: :GET
    end

    scope 'api/admin/users', controller: 'web/admin/user' do
      match 'list' => :get_users_list, via: [:GET, :POST]
      match 'delete-user' => :delete_user, via: :POST
    end

    scope 'api/admin/admin-user', controller: 'web/admin/super_admin' do
      match 'dashboard' => :dashboard, via: :GET
      match 'invite' => :invite, via: :POST
      match 'resend-invite' => :resend_invite, via: :POST
      match 'reset-mfa' => :reset_mfa, via: :POST
      match 'delete-admin' => :delete_admin, via: :POST
    end

    scope 'api/admin/client', controller: 'web/admin/super_admin' do
      match 'update-auto-approve-setting' => :update_auto_approve_setting, via: :POST
      match 'update-sale-setting' => :update_sale_setting, via: :POST
      match 'update-country-setting' => :update_country_setting, via: :POST
    end

    scope 'api/home', controller: 'web/static/home' do
      match '/kyc/contact-us' => :contact_us_pipe_drive_kyc, via: [:GET, :POST]
    end

    scope 'api/callback', controller: 'rest_api/callback/ops' do
      match 'whitelist-event' => :whitelist_event, via: :GET
    end

    match '*permalink', to: 'application#not_found', via: :all
  end


  scope 'api/user', controller: 'web/saas_user/login' do
    match 'sign-up' => :sign_up, via: :POST
    match 'login' => :login, via: :POST
    match 'reset-password' => :reset_password, via: :POST
    match 'send-reset-password-link' => :send_reset_password_link, via: :POST
  end

  scope 'api/user', controller: 'web/saas_user/token_sale' do
    match 'resend-double-opt-in' => :resend_double_opt_in, via: :GET
    match 'kyc-submit' => :kyc_submit, via: :POST
    match 'upload-params' => :get_upload_params, via: :GET
    match 'check-ethereum-address' => :check_ethereum_address, via: :GET
  end

  scope 'api/user', controller: 'web/saas_user/profile' do
    match 'client-detail' => :client_detail, via: :GET
    match 'basic-detail' => :basic_detail, via: :GET
    match 'profile' => :profile, via: :GET
    match 'get-token-sale-address' => :get_token_sale_address, via: :GET
  end


  match '*permalink', to: 'application#not_found', via: :all

end

