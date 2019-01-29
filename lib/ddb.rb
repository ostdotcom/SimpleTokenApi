module Ddb
  extend self

  RETRY_LIMIT = 4

  def client
    fetch_client
  end

  def fetch_client
    Aws::DynamoDB::Client.new(ddb_credentials)
  end

  def ddb_credentials
    GlobalConstant::Base.dynamo_db
  end

end