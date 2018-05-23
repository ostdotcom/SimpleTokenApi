# ENV variables and their development values
source set_env_vars.sh

export PIPEDRIVE_API_TOKEN="3558fceca78678c8fd00c25ea25a21e762d8548f"
export PROJECT_DESCRIPTION_PD_KEY="445d1a8a107f9176d6fef3ab13c1b88ea3c8b742"
export TOKEN_SALE_START_DATE_PD_KEY="8f6bf239cf21f44007f3cb7536ec9d73bc5046c1"
export TOKEN_SALE_END_DATE_PD_KEY="8f6bf239cf21f44007f3cb7536ec9d73bc5046c1_until"
export NEED_FRONT_END_PD_KEY="b8f52fa99548bd23d6cb9c127f430f3efdbb87f7"
export APPLICANT_VOLUME_PD_KEY="39a6b3c6d9a3f3640c17b3dbe9963c020ddc6182"
export KYC_INIT_STAGE_ID=1
export PARTNERS_INIT_STAGE_ID=25

##crons
rake RAILS_ENV=development cron_task:continuous:process_email_service_api_call_hooks lock_key_suffix=1
rake RAILS_ENV=development cron_task:continuous:process_kyc_whitelist_call_hooks lock_key_suffix=1
rake RAILS_ENV=development cron_task:continuous:confirm_kyc_whitelist lock_key_suffix=1
rake RAILS_ENV=development cron_task:lockable:retry_email_service_api_call_hooks
rake RAILS_ENV=development cron_task:lockable:check_eth_balance_of_whitelister
rake RAILS_ENV=development cron_task:lockable:fetch_status_of_pending_cynopsis_users
rake RAILS_ENV=development cron_task:continuous:read_blocks_on_ethernet
rake RAILS_ENV=development cron_task:continuous:process_edit_kycs
rake RAILS_ENV=development cron_task:lockable:upload_failed_cynopsis_users

one-timers
1. Verify scripts
rake verify:purchase_amount_via_purchase_logs RAILS_ENV=development
rake verify:purchasers_via_purchase_logs RAILS_ENV=development
rake verify:whitelist_status_via_kyc_whitelist_logs RAILS_ENV=development
rake verify:whitelist_status_via_user_kyc_details RAILS_ENV=development

2. Purchasers report
rake onetimer:get_purchasers_report RAILS_ENV=development

3. KPI report
rake onetimer:generate_estimated_participation_amount_report RAILS_ENV=development

4. Update Ethereum address
rake onetimer:open_case_and_update_ethereum_address case_id=123 ethereum_address=0x... user_email=example.com admin_email=ignas@simpletoken.org RAILS_ENV=production

5. Users Eth Balance Data
rake RAILS_ENV=development onetimer:generate_ether_balance_of_users_report

6. Open Approved Case
rake onetimer:open_case_and_update_ethereum_address case_id=123 ethereum_address=0x... user_email=example.com admin_email=ignas@simpletoken.org open_case_only=1 RAILS_ENV=production

7. Phase Change from General to Early Access
UserAction::ChangePhase.new(client_id: 1, emails: ['aman+11@pepo.com', 'aman+00@pepo.com'], phase: 'early_access', admin_email: 'abhay@pepo.com').perform

8. send report of processable users st balance on a daily basis
rake RAILS_ENV=development cron_task:continuous:populate_st_balance_for_processable_users




New DB SETUP

rake RAILS_ENV=staging onetimer:insert_general_salt_key_row_in_table salt_type=user_activity_logging
SaleGlobalVariable.create!(variable_kind: 'last_block_verified_for_tokens_sold_variable_kind', variable_data: '2610002')
SaleGlobalVariable.create!(variable_kind: 'pre_sale_tokens_sold_variable_kind', variable_data: '1000000000000000000000')
SaleGlobalVariable.create!(variable_kind: 'pre_sale_eth_received_variable_kind', variable_data: '100000000000000000000')  
    