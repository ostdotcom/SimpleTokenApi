module SaleManagement

  class GetDetails < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Sunil
    #
    # @return [SaleManagement::GetDetails]
    #
    def initialize(params)
      super
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform
      success_with_data(PurchaseLog.sale_details)
    end

  end

end
