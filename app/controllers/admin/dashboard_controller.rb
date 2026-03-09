module Admin
  class DashboardController < BaseController
    skip_after_action :verify_authorized

    def index
    end
  end
end
