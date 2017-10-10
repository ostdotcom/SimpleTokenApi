module AdminManagement

  module Login

    class MultifactorAuth < ServicesBase

      # Initialize
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @param [String] step_1_cookie_value
      # @param [String] otp
      #
      # @return [AdminManagement::Login::MultifactorAuth]
      #
      def initialize(params)
        super

        @step_1_cookie_value = @params[:step_1_cookie_value]
        @otp = @params[:otp]
      end

      def perform
        r = validate
        return r unless r.success?

        r = validate_cookie
        return r unless r.success?

        r = validate_otp
        return r unless r.success?

        r = set_step2_cookie_value
        return r unless r.success?

        success_with_data(
          step_2_cookie_value: @step_2_cookie_value
        )
      end

      private

      # Sets @admin_id
      def validate_cookie

      end

    end

  end

end