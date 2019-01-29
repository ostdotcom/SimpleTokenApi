class AddClientIdInTemporaryToken < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      add_column :temporary_tokens, :client_id, :integer, limit: 8, after: :id, null: true
    end


    ids_map = {}
    TemporaryToken.where(kind: [GlobalConstant::TemporaryToken.double_opt_in_kind,
                                GlobalConstant::TemporaryToken.reset_password_kind]).
    find_in_batches(batch_size: 1000).each do |batch_objs|
      users = User.using_shard(shard_identifier: GlobalConstant::Shard.primary_shard_identifier).
          where(id: batch_objs.pluck(:entity_id)).index_by(&:id)
      batch_objs.each do |temp_token_obj|
        cid = users[temp_token_obj.entity_id].client_id
        ids_map[cid] ||= []
        ids_map[cid] << temp_token_obj.id
      end
    end


    TemporaryToken.where(kind: [GlobalConstant::TemporaryToken.admin_reset_password_kind,
                                GlobalConstant::TemporaryToken.admin_invite_kind]).
    find_in_batches(batch_size: 1000).each do |batch_objs|
      admins = Admin.where(id: batch_objs.pluck(:entity_id)).index_by(&:id)
      batch_objs.each do |temp_token_obj|
        cid = admins[temp_token_obj.entity_id].default_client_id
        ids_map[cid] ||= []
        ids_map[cid] << temp_token_obj.id
      end
    end

    ids_map.each do |cid, tt_ids|
      tt_ids.in_groups_of(300, false).each do |ids|
        TemporaryToken.where(id: ids).update_all(client_id: cid)
        end
    end

    Rails.cache.clear

    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      change_column :temporary_tokens, :client_id, :integer, limit: 8, after: :id, null: false
      remove_index :temporary_tokens, name: 'user_id_kind_status'
      add_index :temporary_tokens, [:client_id, :entity_id, :kind, :status], unique: false, name: 'cid_eid_kind_status'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      add_index :temporary_tokens, [:entity_id, :kind, :status], unique: false, name: 'user_id_kind_status'
      remove_index :temporary_tokens, name: 'cid_eid_kind_status'
      remove_column :temporary_tokens, :client_id
    end
  end
end
