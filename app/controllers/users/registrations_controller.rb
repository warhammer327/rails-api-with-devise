# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  puts "in registration"
  respond_to :json
  private
  def respond_with(resource, option={})
  puts "respond_with function in registration"
    if resource.persisted?
      render json: {
        status: { code: 200, message: 'signed up successfully', data: resource}
      }, status: :ok
    else
      render json: {
        status: {message: 'operation failed', errors: resource.errors.full_messages},
        status: :unprocessable_entity
      }
    end
  end
end
