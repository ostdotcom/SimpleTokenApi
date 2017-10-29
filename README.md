# ENV variables and their development values
#

export SECRET_KEY_BASE="2c83f7055dfb1f11e8698764515bafeb85136f98d864a8fb2246b429d61cf43f91b8d60bdf138abdf11bc0aeb36098964274d9a597bd24fc58751df58f8dd9ac14fb77f56"

export STA_DEFAULT_DB_USER="root"
export STA_DEFAULT_DB_PASSWORD="root"
export STA_DEFAULT_DB_HOST="127.0.0.1"

export STA_DEFAULT_AWS_REGION="us-east-1"
export STA_KYC_S3_BUCKET_NAME='kyc.stagingsimpletoken.org'
export STA_EXTERNAL_DATA_S3_BUCKET_NAME='external-data.simpletoken.org'
export STA_LOGIN_KMS_ARN="arn:aws:kms:us-east-1:604850698061:key"
export STA_LOGIN_KMS_ID="eab8148d-fd9f-451d-9eb9-16c115645635"
export STA_KYC_KMS_ARN="arn:aws:kms:us-east-1:604850698061:key"
export STA_KYC_KMS_ID="5734c3ab-c4ae-4424-a464-2253a4754296"

export STA_USER_AWS_ACCESS_KEY="AKIAJUDRALNURKAVS5IQ"
export STA_USER_AWS_SECRET_KEY="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"
export STA_ADMIN_AWS_ACCESS_KEY="AKIAIAKMZNBD6IWWGNNQ"
export STA_ADMIN_AWS_SECRET_KEY="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"

export STA_REDIS_ENDPOINT=''

export STA_CYNOPSIS_DOMAIN_NAME='SIMPLETOKEN'
export STA_CYNOPSIS_TOKEN='11e73a1b-b41f-425d-b10e-36dfcbdab6ed-1234'
export STA_CYNOPSIS_BASE_URL='https://d1.cynopsis-solutions.com/artemis_simpletoken'

export STA_CAMPAIGN_CLIENT_KEY="0455fbd02e9512168211903ff25094d8"
export STA_CAMPAIGN_CLIENT_SECRET="4c1b4ec0983ab6b1e37d1c1fc31de5e6"
export STA_CAMPAIGN_BASE_URL="https://pepocampaigns.com/"
export STA_CAMPAIGN_MASTER_LIST="2334"
export STA_CAMPAIGN_POS_LIST="2926"

export STA_GEOIP_FILE_WITH_PATH='../GeoIP2-City.mmdb'

export STA_RECAPTCHA_SITE_KEY="6LfbfzQUAAAAAObwp0iXySZxH69WXY6NsLdKZF6B"
export STA_RECAPTCHA_SECRET="6LfbfzQUAAAAAMX0uq9h6ledP8jQSa9BGKSFJyxe"

export STA_EARLY_ACCESS_START_DATE='2017-11-14 13:00:00 UTC'
export STA_GENERAL_ACCESS_START_DATE='2017-11-15 13:00:00 UTC'
export STA_GENERAL_ACCESS_END_DATE='2017-11-21 13:00:00 UTC'
export STA_EARLY_ACCESS_REGISTER_END_DATE='2017-11-10 13:00:00 UTC'

export STA_TOKEN_SALE_ACTIVE_STATUS=1
export STA_FOUNDATION_ETHEREUM_ADDRESS='0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'

export STA_COOKIE_SECRET_KEY='byfd#ss@#4nflkn%^!~wkk^^&71o{23dpi~@jwe$pi'
export STA_EMAIL_TOKENS_DECRIPTOR_KEY='3d3w6fs0983ab6b1e37d1c1fs64hm8g9'

export STA_PRIVATE_OPS_API_BASE_URL='http://172.16.0.181:3000'
export STA_PRIVATE_OPS_API_SECRET_KEY='1somethingsarebetterkeptinenvironemntvariables'
export STA_PUBLIC_OPS_API_BASE_URL='http://172.16.0.179:3001'
export STA_PUBLIC_OPS_API_SECRET_KEY='2somethingsarebetterkeptinenvironemntvariables'

##crons

rake RAILS_ENV=development cron_task:continuous:process_email_service_api_call_hooks lock_key_suffix=1
rake RAILS_ENV=development cron_task:continuous:process_kyc_whitelist_call_hooks lock_key_suffix=1

rake RAILS_ENV=development cron_task:lockable:confirm_kyc_whitelist
rake RAILS_ENV=development cron_task:lockable:retry_email_service_api_call_hooks
rake RAILS_ENV=development cron_task:lockable:fetch_status_of_pending_cynopsis_users



