module UserManagement
  module DocumentsUploader
    module V2
      class ForPut < Base

        # Initialize
        #
        # * Author: Aniket
        # * Date: 03/10/2018
        # * Reviewed By:
        #
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @param [Hash] file (mandatory)
        #
        # @return [UserManagement::DocumentsUploader::V2::ForPut]
        #
        def initialize(params)
          super
        end

        # Perform
        #
        # * Author: Aniket
        # * Date: 03/10/2018
        # * Reviewed By:
        #
        # @return [Result::Base]
        #
        def perform

          super

        end

        private

        # Get AWS Put Url
        #
        # * Author: Aniket
        # * Date: 03/10/2018
        # * Reviewed By:
        #
        # @param [String] content_type
        # @param [String] key
        #
        # @return [Hash]
        #
        def get_url(content_type, key)
          # puts "key : #{key}"
          url = Aws::S3Manager.new('kyc', 'user').get_presigned_put_url_for(
              key, GlobalConstant::Aws::Common.kyc_bucket, content_type)

          {
              url: url,
              fields: {key: key}
          }
        end

      end
    end
  end
end
