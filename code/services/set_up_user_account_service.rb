# frozen_string_literal: true

# This service is used to create and authenticate customer user, send the confirmation email and define
# a redirection url.

class Customer::Sellers::SetUpUserAccountService
  attr_reader :person, :request, :customer_user

  def initialize(person, request)
    @person = person
    @request = request
  end

  def call
    result = create_customer_user
    @customer_user = result[:customer_user]
    error_message = result[:message]
    authentication_token = nil
    redirect_url = nil

    if customer_user_can_be_authenticated?(result)
      auth_result = authenticate_customer_user
      error_message = auth_result[:message]
      authentication_token = auth_result[:authentication_token]
    end

    redirect_url = define_redirect_url(authentication_token) unless error_message.present?
    send_confirmation_email if !result[:account_already_confirmed] && error_message.nil?

    user_response(authentication_token, customer_user&.email, redirect_url, error_message)
  end

  private

  def create_customer_user
    Customer::Sellers::CreateUserService.new(person).call
  end

  def authenticate_customer_user
    Customer::Sellers::AuthenticateUserService.new(request, customer_user).call
  end

  def define_redirect_url(authentication_token)
    Customer::Sellers::DefineRedirectUrlService.new(authentication_token).call
  end

  def send_confirmation_email
    Customer::Sellers::SendConfirmationEmailService.new(customer_user).call
  end

  def customer_user_can_be_authenticated?(create_result)
    create_result[:success] && !create_result[:account_already_confirmed]
  end

  def user_response(authentication_token, email, redirect_url, error_message)
    main_response = { customer_user: {} }

    if error_message.present?
      main_response[:customer_user][:error] = error_message
    else
      main_response[:customer_user][:email] = email
      main_response[:customer_user][:authentication_token] = authentication_token
      main_response[:redirect_url] = redirect_url
    end

    main_response
  end
end
