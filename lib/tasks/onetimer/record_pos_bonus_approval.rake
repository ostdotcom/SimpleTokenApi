namespace :onetimer do

  # rake RAILS_ENV=development onetimer:record_pos_bonus_approval
  task :record_pos_bonus_approval => :environment do

    BgJob.enqueue(
      PosBonusApprovalJob,
      {
        add_to_pepo_campaign_needed: 0,
        pos_file_name: 'mark_pos_without_email.csv'
      }
    )

  end

end