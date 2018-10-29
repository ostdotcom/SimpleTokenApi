module UserManagement
  module DocumentsUploader
    module V2
      class ForPost < Base

        # Initialize
        #
        # * Author: Aniket
        # * Date: 03/10/2018
        # * Reviewed By:
        #
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @param [Hash] file (mandatory)
        #
        # @return [UserManagement::DocumentsUploader::V2::ForPost]
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

        # Get AWS Post Url
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
          post = Aws::S3Manager.new('kyc', 'user').get_presigned_post_url_for(content_type, key, GlobalConstant::Aws::Common.kyc_bucket)

          {url: post.url, fields: post.fields}
        end

      end
    end
  end
end
