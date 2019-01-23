# Created By:: Aman
# Date:: 22/01/19
module ShardHelper

  extend ActiveSupport::Concern

  module ClassMethods
    def using_shard(params)
      GlobalConstant::Shard.get_model(self, params)
    end

    def using_client_shard(params)
      using_shard(shard: params[:client].client_shard.shard_identifier)
    end
  end
end