class Admin::KidsController < Admin::BaseController
  def index
    authorize(Kid)
    @kids = Kid.includes(:user).order(:name)
  end
end
