# ENV variables and their development values
source set_env_vars.sh

##crons
rake RAILS_ENV=development cron_task:continuous:process_email_service_api_call_hooks lock_key_suffix=1
rake RAILS_ENV=development cron_task:continuous:process_kyc_whitelist_call_hooks lock_key_suffix=1
rake RAILS_ENV=development cron_task:continuous:confirm_kyc_whitelist lock_key_suffix=1
rake RAILS_ENV=development cron_task:lockable:retry_email_service_api_call_hooks
rake RAILS_ENV=development cron_task:lockable:check_eth_balance_of_whitelister
rake RAILS_ENV=development cron_task:continuous:read_blocks_on_ethernet
rake RAILS_ENV=development cron_task:lockable:populate_client_usage
rake RAILS_ENV=development cron_task:lockable:refresh_dynamic_gas_price
rake RAILS_ENV=development cron_task:continuous:process_webhooks cron_identifier=p1
rake RAILS_ENV=development cron_task:continuous:process_user_aml_search cron_identifier=p1
rake RAILS_ENV=development cron_task:continuous:process_user_submitted_images_call_hooks cron_identifier=p1

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

4. Users Eth Balance Data
rake RAILS_ENV=development onetimer:generate_ether_balance_of_users_report

5. send report of processable users st balance on a daily basis
rake RAILS_ENV=development cron_task:continuous:populate_st_balance_for_processable_users


New DB SETUP

command to generate a key for local cipher- SecureRandom.hex

rake RAILS_ENV=development onetimer:insert_general_salt_key_row_in_table salt_type=user_activity_logging
SaleGlobalVariable.create!(variable_kind: 'last_block_verified_for_tokens_sold_variable_kind', variable_data: '2610002')
SaleGlobalVariable.create!(variable_kind: 'pre_sale_tokens_sold_variable_kind', variable_data: '1000000000000000000000')
SaleGlobalVariable.create!(variable_kind: 'pre_sale_eth_received_variable_kind', variable_data: '100000000000000000000')  
    