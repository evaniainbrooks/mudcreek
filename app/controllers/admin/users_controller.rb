class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show]

  def index
    authorize(User)
    @roles = Role.order(:name)
    @q = User.ransack(params[:q])
    scope = @q.result.includes(:role).order(id: :asc)
    @pagy, @users = pagy(:keyset, scope)
  end

  def show
  end

  private

  def set_user
    @user = User.find(params[:id])
    authorize(@user)
  end
end
