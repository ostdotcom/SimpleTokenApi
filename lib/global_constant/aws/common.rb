# frozen_string_literal: true
module GlobalConstant

  module Aws

    class Common

      class << self

        def get_credentials_for(role)
          if role == 'user'
            user_access_credentials
          elsif role == 'admin'
            admin_access_credentials
          else
            fail 'invalid role'
          end
        end

        def region
          GlobalConstant::Base.aws['region']
        end

        def kyc_bucket
          GlobalConstant::Base.s3['kyc_bucket']
        end

        private

        def user_access_credentials
          GlobalConstant::Base.aws['user']
        end

        def admin_access_credentials
          GlobalConstant::Base.aws['admin']
        end

      end

    end

  end

end