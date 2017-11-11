module ContractEventManagement

  class Finalize < Base

    # initialize
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [ContractEventManagement::Finalize]
    #
    def initialize(params)
      super
    end

    # Perform
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def perform
      _perform do
        update_token_sale_ended_data
      end
    end

    private

    # Update token sale ended variable
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    def update_token_sale_ended_data
      sale_variable_obj = SaleGlobalVariable.sale_ended.first
      sale_variable_obj.variable_data = '1'
      sale_variable_obj.save!
    end

  end

end