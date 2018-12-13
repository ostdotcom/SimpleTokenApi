namespace :onetimer do

  # Add Show Sale Timer Key In Entity Draft Table
  #
  # * Author: Tejas
  # * Date: 27/07/2018
  # * Reviewed By:
  #
  # rake RAILS_ENV=development onetimer:add_show_sale_timer_key_in_entity_draft_table
  task :add_show_sale_timer_key_in_entity_draft_table => :environment do
    EntityDraft.all.each do |ed|
      entity_draft_data = ed.data
      entity_draft_data.merge!(show_sale_timer: '1') if entity_draft_data[:dashboard_title_text_color].present?
      ed.save! if ed.changed?
    end
    Rails.cache.clear
  end
end