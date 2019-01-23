class ClientShard < EstablishSimpleTokenClientDbConnection

  scope :of_client, ->(client_ids) { where(client_id: client_ids) }

end
