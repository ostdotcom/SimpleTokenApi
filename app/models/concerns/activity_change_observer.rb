module ActivityChangeObserver

  extend ActiveSupport::Concern

  included do
    attr_accessor :source, :logged_admin_id, :log_sync
    after_save :create_entry_in_logger
  end

  def log_sync!
    self.log_sync = true
  end

  def log_sync?
    self.log_sync
  end

  def table_name
    self.class.table_name
  end

  def table_columns_to_observe
    @table_columns_to_observe ||= AdminActivityChangeLogger::TABLE_ALLOWED_KEYS_MAPPING[table_name][:columns]
  end

  def create_entry_in_logger
    saved_changes = self.saved_changes
    columns_to_log = (saved_changes.keys & table_columns_to_observe)


    if columns_to_log.present?
      if source.blank? || AdminActivityChangeLogger.sources.keys.exclude?(source)
        ApplicationMailer.notify(body: "source is invalid",
                                 data: {source: source, table_name: table_name},
                                 subject: "Exception in ActivityChangeObserver. Source invalid."
        ).deliver
        return
      end

      columns_to_log.each do |col_name|
        col_change_val = saved_changes[col_name]
        params = {
            client_id: self.client_id,
            admin_id: get_admin_id,
            entity_type: table_name,
            entity_id: self.id,
            source: self.source,
            column_name: col_name,
            old_val: col_change_val[0],
            new_val: col_change_val[1]
        }
        if self.log_sync?
          AdminActivityLoggerJob.perform_now(params)
        else
          BgJob.enqueue(AdminActivityLoggerJob, params)
        end
      end

    end
  end

  def get_admin_id
    (self.logged_admin_id || self.try(:last_acted_by)).to_i
  end

end