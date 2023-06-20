class MembersController < ApplicationController
    before_action :authenticate_user!
    def index
        #@users = User.all
        #render json: @users, status: :ok
        render json: current_user, status: :ok
    end
end
