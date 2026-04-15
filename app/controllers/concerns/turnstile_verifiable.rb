module TurnstileVerifiable
  extend ActiveSupport::Concern

  included do
    before_action :set_turnstile_widget
  end

  private

  def set_turnstile_widget
    @turnstile_widget = Cloudflare::TurnstileWidget.find_by(tenant: Current.tenant)
  end

  def verify_turnstile!
    return unless @turnstile_widget

    token = params["cf-turnstile-response"]
    result = token.present? && CloudflareClient.new.verify_token(
      secret: @turnstile_widget.secret,
      token: token,
      remote_ip: request.remote_ip
    )

    unless result && result[:success]
      redirect_to new_session_path, alert: "Please complete the security challenge.", status: :see_other
    end
  end
end
