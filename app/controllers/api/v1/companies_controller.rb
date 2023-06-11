class Api::V1::CompaniesController < ApiController
  before_action :set_company, only: [:show]
  def index
  @companies = current_user.companies
  end

  def show
    render json: @company, status: :ok
  end

  def create
    @company = Company.new(company_params)
  end

  private

  def set_company
    @company = current_user.companies.find(params[:id])
  rescue ActiveRecord::RecordNotFound => errors
    render json: error.message, status: :unauthorized
  end

  def company_params
    params.requrie(:company).permit(:name, :year, :user_id)
  end
end
