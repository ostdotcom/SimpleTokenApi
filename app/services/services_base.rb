class ServicesBase

  include Util::ResultHelper

  attr_reader :params

  # Initialize ServiceBase instance
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def initialize(service_params={})
    service_klass = self.class.to_s
    service_params_list = ServicesBase.get_service_params(service_klass)

    # passing only the mandatory and optional params to a service
    permitted_params_list = ((service_params_list[:mandatory] || []) + (service_params_list[:optional] || [])) || []

    permitted_params = {}

    permitted_params_list.each do |pp|
      permitted_params[pp] = service_params[pp]
    end

    @params = HashWithIndifferentAccess.new(permitted_params)
  end

  # Method to get service params from yml file
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  def self.get_service_params(service_class)
    # Load mandatory params yml only once
    @mandatory_params ||= YAML.load_file(open(Rails.root.to_s + '/app/services/service_params.yml'))
    @mandatory_params[service_class]
  end

  # Current Time
  #
  # * Author: Sunil Khedar
  # * Date: 19/10/2017
  # * Reviewed By: Kedar
  #
  def current_time
    @c_t ||= Time.now
  end

  # Current Time Stamp
  #
  # * Author: Sunil Khedar
  # * Date: 19/10/2017
  # * Reviewed By: Kedar
  #
  def current_timestamp
    @c_tstmp ||= current_time.to_i
  end

  private

  # Method to validate presence of params
  #
  # * Author: Kedar
  # * Date: 09/10/2017
  # * Reviewed By: Sunil Khedar
  #
  # @return [Result::Base]
  #
  def validate
    # perform presence related validations here
    # result object is returned
    service_params_list = ServicesBase.get_service_params(self.class.to_s)
    missing_mandatory_params = []
    service_params_list[:mandatory].each do |mandatory_param|
      missing_mandatory_params << "missing_#{mandatory_param}" if @params[mandatory_param].to_s.blank?
    end if service_params_list[:mandatory].present?

    return error_with_identifier('mandatory_params_missing',
                                 'sb_1',
                                 missing_mandatory_params
    ) if missing_mandatory_params.any?

    success
  end

  # fetch client and validate
  #
  # * Author: Aman
  # * Date: 26/12/2017
  # * Reviewed By:
  #
  # Sets @client
  #
  # @return [Result::Base]
  #
  def fetch_and_validate_client
    @client = Client.get_from_memcache(@client_id)

    return error_with_identifier('invalid_client_id','sb_2') if
        @client.blank? || @client.status != GlobalConstant::Client.active_status

    success
  end

  # fetch admin and validate
  #
  # * Author: Aman
  # * Date: 24/04/2018
  # * Reviewed By:
  #
  # Sets @admin
  #
  # @return [Result::Base]
  #
  def fetch_and_validate_admin
    @admin = Admin.get_from_memcache(@admin_id)

    return error_with_identifier('invalid_admin_id','sb_3') if
        @admin.status != GlobalConstant::Admin.active_status

    success
  end

  # Unauthorized request
  #
  # * Author: Pankaj
  # * Date: 20/09/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def unauthorized_access_response(internal_error_code)
    error_with_identifier("unauthorized_access", internal_error_code)
  end

end