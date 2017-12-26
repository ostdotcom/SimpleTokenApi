class Client < EstablishSimpleTokenClientDbConnection

  enum status: {
           GlobalConstant::Client.active_status => 1,
           GlobalConstant::Client.inactive_status => 2
       }

  # Array of Properties symbols
  #
  # * Author: Aman
  # * Date: 26/10/2017
  # * Reviewed By:
  #
  # @returns [Array<Symbol>] returns Array of setup properties bits set for client
  #
  def setup_properties_array
    @setup_properties_array = Client.get_bits_set_for_setup_properties(setup_properties)
  end

  # setup properties config
  #
  # * Author: Aman
  # * Date: 26/10/2017
  # * Reviewed By:
  #
  def self.setup_properties_config
    @setup_properties_config ||= {
        GlobalConstant::Client.cynopsis_setup_done => 1,
        GlobalConstant::Client.email_setup_done => 2,
        GlobalConstant::Client.whiteliste_setup_done => 4
    }
  end

  # Bitwise columns config
  #
  # * Author: Aman
  # * Date: 26/10/2017
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        setup_properties: setup_properties_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

end