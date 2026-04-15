class Admin::TurnstilesController < Admin::BaseController
  def index
    authorize(Cloudflare::TurnstileWidget, policy_class: Cloudflare::TurnstileWidgetPolicy)
    @widget = Cloudflare::TurnstileWidget.find_by(tenant: Current.tenant)
  end
end
