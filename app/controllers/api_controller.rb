class ApiController < ApplicationController
  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    render json: {waring: exception, status: 'autrhorization failed'}
  end
end
