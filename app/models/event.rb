class Event < EstablishOstKycWebhookDbConnection

  NAME_CONFIG = {
      GlobalConstant::Event.user_register_name => {
          entity_val: 1,
          description: 'User has signed up',
          result_type: GlobalConstant::Event.user_result_type
      },
      GlobalConstant::Event.user_dopt_in_name => {
          entity_val: 2,
          description: 'User has done double opt in',
          result_type: GlobalConstant::Event.user_result_type
      },
      GlobalConstant::Event.user_deleted_name => {
          entity_val: 3,
          description: 'User was deletd by admin',
          result_type: GlobalConstant::Event.user_result_type
      },
      GlobalConstant::Event.kyc_submit_name => {
          entity_val: 4,
          description: 'User has submitted kyc data',
          result_type: GlobalConstant::Event.user_result_type
      },
      GlobalConstant::Event.update_ethereum_address_name => {
          entity_val: 5,
          description: 'Admin has updates ethereum address of user',
          result_type: GlobalConstant::Event.user_result_type
      },
      GlobalConstant::Event.kyc_status_update_name => {
          entity_val: 6,
          description: 'user kyc state has changed',
          result_type: GlobalConstant::Event.user_result_type
      }
  }

  enum result_type: {
      GlobalConstant::Event.user_result_type => 1,
      GlobalConstant::Event.user_kyc_result_type => 2
  }

  enum source: {
      GlobalConstant::Event.web_source => 1,
      GlobalConstant::Event.api_source => 2,
      GlobalConstant::Event.kyc_system_source => 3
  }

  enum name: begin
    name_map = {}
    NAME_CONFIG.each do |e_name, e_data|
      name_map[e_name] = e_data[:entity_val]
    end
    name_map.freeze
  end

  serialize :data, Hash







  def self.get_event_result_type(name)
    Event::NAME_CONFIG[name.to_s][:result_type]
  end

end
