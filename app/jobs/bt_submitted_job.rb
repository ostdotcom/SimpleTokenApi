class BtSubmittedJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :que2

  # Perform
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By:
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
  # * Reviewed By:
  #
  def init_params(params)
    @user_id = params[:user_id]
    @user = User.find(@user_id)
  end

  # Create Double Opt In Token
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By:
  #
  def create_double_opt_in_token
    db_row = TokenSaleDoubleOptInToken.find_or_initialize_by(user_id: @user_id)
    if db_row.present?
      @double_opt_in_token = db_row.token
    else
      @double_opt_in_token = Digest::MD5.hexdigest("#{@user_id}::#{@user.email}::#{Time.now.to_i}::token_sale_double_opt_in::#{rand}")
      db_row.token = @double_opt_in_token
      db_row.save
    end
  end

  # Send token sale mail
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By:
  #
  def send_token_sale_double_opt_in_mail
    Email::HookCreator::SendTransactionalMail.new(
      email: @user.email,
      double_opt_in_token: @double_opt_in_token,
      template_name: GlobalConstant::PepoCampaigns.double_opt_in_template,
      template_vars: {
        double_opt_in_token: @double_opt_in_token
      }
    ).perform
  end

end
