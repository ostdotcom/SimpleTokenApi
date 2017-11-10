module ContractEventManagement

  class Base < ServicesBase

    # initialize
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [ContractEventManagement::Base]
    #
    def initialize(params)
      super
      @contract_event_obj = @params[:contract_event_obj]
    end

    private

    # perform these steps
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    def _perform(&block)

      begin

        r = validate
        return r unless r.success?

        yield if block_given?

        mark_contract_event_as_processed

        success

      rescue StandardError => se

        mark_contract_event_as_failed

        return exception_with_data(
          se,
          'cem_b_1',
          'exception in contract event management: ' + se.message,
          'Something went wrong.',
          GlobalConstant::ErrorAction.default,
          {contract_event_obj_id: @contract_event_obj.id}
        )

      end

    end

    # mark contract event as processed
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    def mark_contract_event_as_processed
      @contract_event_obj.status = GlobalConstant::ContractEvent.processed_status
      @contract_event_obj.save!
    end

    # mark contract event as failed
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    def mark_contract_event_as_failed
      @contract_event_obj.status = GlobalConstant::ContractEvent.failed_status
      @contract_event_obj.save!
    end

  end

end