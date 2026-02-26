class Admin::UsersController < Admin::BaseController
  def index
    authorize(User)
    @roles = Role.order(:name)
    @q = User.ransack(params[:q])
    scope = @q.result.includes(:role).order(id: :asc)
    @pagy, @users = pagy(:keyset, scope)
  end
end
