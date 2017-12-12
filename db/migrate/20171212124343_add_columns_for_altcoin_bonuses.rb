class AddColumnsForAltcoinBonuses < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do

      add_column :alt_coin_bonus_logs, :alt_token_amount_in_wei, :decimal, precision: 30, null: true, after: :altcoin_bonus_wei_value
      add_column :alt_coin_bonus_logs, :transfer_transaction_hash, :string, null: true, after: :alt_token_amount_in_wei
      add_column :alt_coin_bonus_logs, :alt_token_contract_address, :string, null: true, after: :alt_token_name

    end

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do

      add_column :alternate_tokens, :contract_address, :string, null: true, after: :token_name

    end

    token_contract_addresses = {
        "ST" => "0x2C4e8f2D746113d0696cE89B35F0d8bF88E0AEcA",
        "0x" => "0xe41d2489571d322189246dafa5ebde1f4699f498",
        "AdEx" => "0x4470bb87d77b963a013db939be332f927f2b992e",
        "Aeternity" => "0x5ca9a71b1d01849c0a95490cc00559717fcf0d1d",
        "AirSwap" => "0x27054b13b1b798b345b591a4d22e6562d47ea75a",
        "Aragon" => "0x960b236A07cf122663c4303350609A66A7B288C0",
        "ATMChain" => "0x9B11EFcAAA1890f6eE52C6bB7CF8153aC5d74139",
        "Augur" => "0xe94327d07fc17907b4db788e5adf2ed424addff6",
        "Bancor" => "0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c",
        "Basic Attention Token" => "0x0d8775f648430679a709e98d2b0cb6250d2887ef",
        "Bitquence" => "0x5af2be193a6abca9c8817001f45744777db30756",
        "ChainLink" => "0x514910771af9ca656af840dff83e8264ecf986ca",
        "Civic" => "0x41e5560054824ea6b0732e656e3ad64e20e94e45",
        "Decentraland" => "0x0f5d2fb29fb7d3cfee444a200298f468908cc942",
        "District0x" => "0x0abdace70d3790235af448c88547603b945604ea",
        "Edgeless" => "0x08711d3b02c8758f2fb3ab4e80228418a7f8e39c",
        "EOS" => "0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0",
        "FunFair" => "0x419d0d8bdd9af5e606ae2232ed285aff190e711b",
        "Gnosis" => "0x6810e776880c02933d47db1b9fc05908e5386b96",
        "Golem" => "0xa74476443119A942dE498590Fe1f2454d7D4aC0d",
        "Iconomi" => "0x888666CA69E0f178DED6D75b5726Cee99A87D698",
        "Kin" => "0x818fc6c2ec5986bc6e2cbf00939d90556ab12ce5",
        "Kyber Network" => "0xdd974d5c2e2928dea5f71b9825b8b646686bd200",
        "Loopring" => "0xef68e7c694f40c8202821edf525de3782458639f",
        "MCAP" => "0x93e682107d1e9defb0b5ee701c71707a4b2e46bc",
        "Melon" => "0xBEB9eF514a379B997e0798FDcC901Ee474B6D9A1",
        "Metal" => "0xF433089366899D83a9f26A773D59ec7eCF30355e",
        "Modum" => "0x957c30ab0426e0c93cd8241e2c60392d08c6ac8e",
        "Moeda Loyalty Points" => "0x51db5ad35c671a87207d88fc11d593ac0c8415bd",
        "Monaco" => "0xb63b606ac810a52cca15e44bb630fd42d8d1d83d",
        "OmiseGO" => "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07",
        "Populous" => "0xd4fa1460f537bb9085d22c7bccb5dd450ef28e3a",
        "SALT" => "0x4156D3342D5c385a87D264F90653733592000581",
        "SingularDTV" => "0xaec2e87e0a235266d9c5adc9deb4b2e29b54d009",
        "Status" => "0x744d70fdbe2ba4cf95131626614a1763df805b9e",
        "Storj" => "0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac",
        "TenX" => "0xB97048628DB6B661D4C2aA833e95Dbe1A905B280",
        "TRON" => "0xf230b790e05390fc8295f4d3f60332c93bed42e2",
        "Walton" => "0xb7cb1c96db6b22b0d3d9536e0108d062bd488f74",
        "Wings" => "0x667088b212ce3d06a1b553a7221E1fD19000d9aF"
    }

    alternate_tokens = AlternateToken.all.index_by(&:token_name)
    alternate_tokens.each do |name, alt_token|
      alt_token.contract_address = token_contract_addresses[name]
      alt_token.save
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do

      remove_column :alt_coin_bonus_logs, :alt_token_amount_in_wei
      remove_column :alt_coin_bonus_logs, :transfer_transaction_hash
      remove_column :alt_coin_bonus_logs, :alt_token_contract_address

    end

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do

      remove_column :alternate_tokens, :contract_address

    end
  end
end
