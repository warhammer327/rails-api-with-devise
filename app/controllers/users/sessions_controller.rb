# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  puts "starting session"
  respond_to :json
  private
  def respond_with(resource, option={})
  puts "respond_with function in session"
      render json: {
        status: { code: 200, message: 'signed in: '+current_user.email , data: current_user}
      }, status: :ok
  end

  def respond_to_on_destroy
  puts "respond_to_on_destroy function in session"
    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ')[1],Rails.application.credentials.fetch(:secret_key_base)).first
    current_user = User.find(jwt_payload['sub'])
    if current_user
      render json: {
        status: 200,
        message: "signed out user: " + current_user.email
      }, status: :ok
    else
      render json: {
        status: 401,
        messages: "user has no active session"
      }, status: :unauthorized
    end
  end
end
