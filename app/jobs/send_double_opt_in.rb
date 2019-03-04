class SendDoubleOptIn < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def perform(params)

    init_params(params)

    return unless @user.send(GlobalConstant::User.doptin_mail_sent_property + "?")

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
    @client_id = params[:client_id]
    @user_id = params[:user_id]

    @client = Client.get_from_memcache(@client_id)
    @user = User.using_client_shard(client: @client).find(@user_id)
    @double_opt_in_token = nil
  end

  # Create Double Opt In Token
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def create_double_opt_in_token
    t_double_opt_in_token = Digest::MD5.hexdigest("#{@user_id}::#{@user.email}::#{Time.now.to_i}::token_sale_double_opt_in::#{rand}")
    db_row = TemporaryToken.create!(
        {
            client_id: @client_id,
            entity_id: @user_id, kind: GlobalConstant::TemporaryToken.double_opt_in_kind,
            token: t_double_opt_in_token
        }
    )

    double_opt_in_token_str = "#{db_row.id.to_s}:#{t_double_opt_in_token}"
    encryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.email_tokens_key)
    r = encryptor_obj.encrypt(double_opt_in_token_str)
    return r unless r.success?
    @double_opt_in_token = r.data[:ciphertext_blob]
  end

  # Send token sale mail
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def send_token_sale_double_opt_in_mail
    Email::HookCreator::SendTransactionalMail.new(
        client_id: @client_id,
        email: @user.email,
        template_name: GlobalConstant::PepoCampaigns.double_opt_in_template,
        template_vars: {
            double_opt_in_token: @double_opt_in_token
        }
    ).perform if @double_opt_in_token.present?
  end

end
