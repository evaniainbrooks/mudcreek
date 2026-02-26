module Admin
  class BaseController < ApplicationController
    include Pundit::Authorization

    after_action :verify_authorized

    before_action { @admin = true }

    private

    def pundit_user
      Current.user
    end
  end
end
