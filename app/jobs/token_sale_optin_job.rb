class TokenSaleOptinJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def perform(params)

    init_params(params)

    create_double_opt_in_token

    send_token_sale_double_opt_in_mail

  end

  private

  # Init params
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def init_params(params)
    @user_id = params[:user_id]
    @user = User.find(@user_id)
    @double_opt_in_token = nil
  end

  # Create Double Opt In Token
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def create_double_opt_in_token
    db_row = TemporaryToken.find_or_initialize_by(user_id: @user_id, kind: GlobalConstant::TemporaryToken.double_opt_in_kind)
    if db_row.new_record?
      t_double_opt_in_token = Digest::MD5.hexdigest("#{@user_id}::#{@user.email}::#{Time.now.to_i}::token_sale_double_opt_in::#{rand}")
      db_row.token = t_double_opt_in_token
      db_row.save!
    else
      t_double_opt_in_token = db_row.token if db_row.status == GlobalConstant::TemporaryToken.active_status
    end

    @double_opt_in_token = "#{db_row.id.to_s}:#{t_double_opt_in_token}" if t_double_opt_in_token.present?
  end

  # Send token sale mail
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def send_token_sale_double_opt_in_mail
    Email::HookCreator::SendTransactionalMail.new(
      email: @user.email,
      template_name: GlobalConstant::PepoCampaigns.double_opt_in_template,
      template_vars: {
        double_opt_in_token: @double_opt_in_token
      }
    ).perform if @double_opt_in_token.present?
  end

end
