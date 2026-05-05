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

    Rails.logger.info("[Turnstile] token present=#{token.present?}, secret present=#{@turnstile_widget.secret.present?}")

    result = token.present? && CloudflareClient.new.verify_token(
      secret: @turnstile_widget.secret,
      token: token,
      remote_ip: request.remote_ip
    )

    Rails.logger.info("[Turnstile] result=#{result.inspect}")

    unless result && result[:success]
      redirect_to new_session_path, alert: I18n.t("turnstile_verifiable.alert"), status: :see_other
    end
  end
end
