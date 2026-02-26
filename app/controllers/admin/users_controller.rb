class Admin::UsersController < Admin::BaseController
  def index
    authorize(User)
    @q = User.ransack(params[:q])
    scope = @q.result.order(id: :asc)
    @pagy, @users = pagy(:keyset, scope)
  end
end
