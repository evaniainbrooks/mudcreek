class Admin::Cloudflare::TurnstileWidgetsController < Admin::BaseController
  def create
    authorize(Cloudflare::TurnstileWidget, policy_class: Cloudflare::TurnstileWidgetPolicy)
    ProvisionCloudflareTurnstileJob.perform_later(Current.tenant.id)
    redirect_to admin_turnstiles_path, notice: "Turnstile widget provisioning has been enqueued."
  end
end
