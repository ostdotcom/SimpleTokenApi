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
          elsif role == 'general_access'
            general_access_credentials
          elsif role == 'saas'
            saas_access_credentials
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

        def report_bucket
          GlobalConstant::Base.s3['report_bucket']
        end

        def client_assets_bucket
          GlobalConstant::Base.s3['client_assets_bucket']
        end

        private

        def user_access_credentials
          GlobalConstant::Base.aws['user']
        end

        def admin_access_credentials
          GlobalConstant::Base.aws['admin']
        end

        def general_access_credentials
          GlobalConstant::Base.aws['admin']
        end

        def saas_access_credentials
          GlobalConstant::Base.aws['saas']
        end

      end

    end

  end

end