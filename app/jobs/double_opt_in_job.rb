class DoubleOptInJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  # Perform
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def perform(params)

    init_params(params)

    create_email_service_api_call_hook

    associate_ued_with_user

    call_cynopsis_api

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
    @user_extended_detail = UserExtendedDetail.where(user_id: @user_id).last
  end

  # Create Hook to sync data in Email Service
  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  def create_email_service_api_call_hook
    Email::HookCreator::AddContact.new(
      email: @user.email,
      token_sale_phase: GlobalConstant::TokenSale.token_sale_phase_for
    ).perform
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  # Sets @user_extended_detail
  #
  def associate_ued_with_user
    @user.user_extended_detail_id = @user_extended_detail.id
    @user.save!
  end

  #
  # * Author: Kedar, Puneet
  # * Date: 12/10/2017
  # * Reviewed By: Sunil
  #
  #
  # @params [String] rfrID (mandatory) - Customer reference id
  # @params [String] first_name (mandatory) - Customer first name
  # @params [String] last_name (mandatory) - Customer last name
  # @params [String] country_of_residence (mandatory) - Customer residence country
  # @params [String] date_of_birth (mandatory) - Customer date of birth (format: "%d/%m/%Y")
  # @params [String] identification_type (mandatory) - Customer identification type
  # @params [String] identification_number (mandatory) - Customer identification number
  # @params [String] nationality (mandatory) - Customer nationality
  # @params [Array] emails (mandatory) - Customer email addresses
  # @params [String] addresses (mandatory) - Customer address separated by comma
  #
  def call_cynopsis_api
    Cynopsis::Customer.new().create(
      rfrID: "ts2_#{@user_id}",
      first_name: first_name,
      last_name: last_name,
      country_of_residence: country_of_residence,
      date_of_birth: date_of_birth,
      identification_type: 'passport',
      identification_number: passport_number,
      nationality: nationality,
      emails: [],
      addresses: []
    )
  end

end
