# Created By:: Aman
# Date:: 22/01/19
module ShardHelper

  extend ActiveSupport::Concern

  module ClassMethods
    def using_shard(params)
      GlobalConstant::Shard.get_model(self, params)
    end

    def using_client_shard(params)
      using_shard(shard_identifier: params[:client].client_shard.shard_identifier)
    end

    def use_any_instance
      params = {shard_identifier: GlobalConstant::Shard.primary_shard_identifier}
      GlobalConstant::Shard.get_model(self, params)
    end

  end
end