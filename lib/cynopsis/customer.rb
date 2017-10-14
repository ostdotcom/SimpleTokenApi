module Cynopsis

  class Customer < Cynopsis::Base

    # Initialize
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @return [Cynopsis::Customer]
    #
    def initialize
      super
    end

    # Create individual customer
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @params [String] rfrID (mandatory) - Customer reference id
    # @params [String] first_name (mandatory) - Customer first name
    # @params [String] last_name (mandatory) - Customer last name
    # @params [String] country_of_residence (mandatory) - Customer residence country
    # @params [String] date_of_birth (mandatory) - Customer date of birth (format: "%d/%m/%Y")
    # @params [String] identification_type (mandatory) - Customer identification type
    # @params [String] identification_number (mandatory) - Customer identification number
    # @params [String] nationality (mandatory) - Customer nationality
    # @params [Array] emails (mandatory) - Customer email addresses
    # @params [String] addresses (mandatory) - Customer address separated by comma
    #
    # @return [Result::Base]
    #
    def create(params)
      params[:domain_name] = GlobalConstant::Cynopsis.domain_name
      params.merge!(default_mandatory_api_params)

      post_request('/default/individual_risk', params)
    end

    # Update individual customer
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @params [String] rfrID (mandatory) - Customer reference id
    # @params [String] first_name (mandatory) - Customer first name
    # @params [String] last_name (mandatory) - Customer last name
    # @params [String] country_of_residence (mandatory) - Customer residence country
    # @params [String] date_of_birth (mandatory) - Customer date of birth (format: "%d/%m/%Y")
    # @params [String] identification_type (mandatory) - Customer identification type
    # @params [String] identification_number (mandatory) - Customer identification number
    # @params [String] nationality (mandatory) - Customer nationality
    # @params [Array] emails (mandatory) - Customer email addresses
    # @params [String] addresses (mandatory) - Customer address separated by comma
    #
    # @return [Result::Base]
    #
    def update(params, re_assess = false)
      params[:domain_name] = GlobalConstant::Cynopsis.domain_name
      # Set new if you are sending the completely new data and want new scan
      params[:re_assess] = re_assess
      params.merge!(default_mandatory_api_params)

      put_request('/default/update_individual', params)
    end

    # Check customer status
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @params [String] rfrID (mandatory) - Customer reference id
    #
    # @return [Result::Base]
    #
    def check_status(params)
      params[:domain_name] = GlobalConstant::Cynopsis.domain_name

      get_request('/default/check_status.json', params)
    end

    private

    # Append mandatory default api params
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def default_mandatory_api_params
      {
        ssic_code: 'UNKNOWN',
        ssoc_code: 'UNKNOWN',
        onboarding_mode: 'NON FACE-TO-FACE',
        payment_mode: 'UNKNOWN',
        product_service_complexity: 'COMPLEX'
      }
    end

  end

end