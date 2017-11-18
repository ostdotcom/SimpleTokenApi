
namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:backpopulate_transaction_hash_in_purchase_log

  task :backpopulate_transaction_hash_in_purchase_log => :environment do

    invalid_contract_events = {}
    contract_events_by_address = {}

    ContractEvent.where(kind: GlobalConstant::ContractEvent.tokens_purchased_kind).
      order(:block_number).each do |contract_event|

      beneficiary_data = contract_event.data[:event_data].select{|k| k[:name] == '_beneficiary'}.first
      st_purchased_data = contract_event.data[:event_data].select{|k| k[:name] == '_tokens'}.first

      if beneficiary_data.blank? || st_purchased_data.blank?
        invalid_contract_events[contract_event.id] = {
          beneficiary_data: beneficiary_data,
          st_purchased_data: st_purchased_data
        }
      end

      contract_events_by_address[beneficiary_data[:value]] ||= []

      contract_events_by_address[beneficiary_data[:value]] << {
        st_wei_value: st_purchased_data[:value].to_i,
        transaction_hash: contract_event.transaction_hash
      }

    end

    purchase_logs_by_address = {}

    PurchaseLog.all.order(:block_creation_timestamp).each do |purchase_log|
      
      purchase_logs_by_address[purchase_log.ethereum_address] ||= []

      transaction_hash = purchase_log.transaction_hash rescue nil
      purchase_logs_by_address[purchase_log.ethereum_address] << {
        st_wei_value: purchase_log.st_wei_value,
        id: purchase_log.id,
        transaction_hash: transaction_hash
      }

    end

    problamatic_eth_addresses = []
    problamatic_eth_addresses += purchase_logs_by_address.keys - contract_events_by_address.keys
    problamatic_eth_addresses += contract_events_by_address.keys - purchase_logs_by_address.keys

    fail "problamatic_keys: #{problamatic_eth_addresses}" if problamatic_eth_addresses.any?

    problamatic_addresses = {}

    purchase_logs_by_address.each do |eth_address, purchase_logs_transactions|

      contract_events_data = contract_events_by_address[eth_address]

      if contract_events_data.length != purchase_logs_transactions.length
        problamatic_addresses[eth_address] = {
          transactions_from_contract_events: contract_events_data,
          transactions_from_purchase_orders: purchase_logs_transactions
        }
        next
      end

      contract_events_data.each_with_index do |contract_event_data, index|
        if contract_event_data[:st_wei_value] != purchase_logs_transactions[index][:st_wei_value]
          problamatic_addresses[eth_address] ||= {value_mismatches: {}}
          problamatic_addresses[eth_address][:value_mismatches][index] = {
            value_from_contract_events: contract_event_data[:st_wei_value],
            value_from_purchase_orders: purchase_logs_transactions[index][:st_wei_value]
          }
        end
      end
      next if problamatic_addresses[eth_address].present?

      contract_events_data.each_with_index do |contract_event_data, index|
        purchase_log_transaction = purchase_logs_transactions[index]
        next if purchase_log_transaction[:transaction_hash].present?
        puts "#{eth_address} : #{contract_event_data[:st_wei_value]} : #{purchase_log_transaction[:id]} : #{contract_event_data[:transaction_hash]}"
        pl = PurchaseLog.find(purchase_log_transaction[:id])
        pl.transaction_hash = contract_event_data[:transaction_hash]
        pl.save
      end

    end

  end

end
