class Admin::KidsController < Admin::BaseController
  def index
    authorize(Kid)
    @filter_total = Kid.count
    @q = Kid.ransack(params[:q])
    scope = @q.result.includes(:user).order(:name)
    @filter_count = scope.count
    @kids = scope
  end
end
