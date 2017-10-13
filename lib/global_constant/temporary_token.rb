# frozen_string_literal: true
module GlobalConstant

  class TemporaryToken

    class << self

      ########## Statuses ###########

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      def used_status
        'used'
      end

      ########## Statuses ###########

      ########## Kinds ###########

      def double_opt_in_kind
        'double_opt_in'
      end

      def reset_password_kind
        'reset_password'
      end

      ########## Kinds ###########

      ########## expiry intervals ###########

      def reset_token_expiry_interval
        30.minutes
      end

      def double_opt_in_expiry_interval
        15.days
      end

      ########## Kinds ###########

    end

  end


end
