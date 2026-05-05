class OauthCallbacksController < ApplicationController
  allow_unauthenticated_access only: %i[create failure]
  skip_forgery_protection only: :create  # Apple POSTs from appleid.apple.com

  def create
    auth = request.env["omniauth.auth"]

    if auth.info.email.blank?
      return redirect_to new_session_path,
        alert: t(".alert_no_email", provider: auth.provider.humanize)
    end

    # uid lookup is global (provider+uid is unique across tenants)
    identity = OauthIdentity.unscoped.find_by(provider: auth.provider, uid: auth.uid)

    if identity
      user = identity.user
      identity.update!(access_token: auth.credentials&.token,
                       refresh_token: auth.credentials&.refresh_token,
                       token_expires_at: expires_at(auth))
    else
      user = User.find_by("lower(email_address) = ?", auth.info.email.downcase)

      if user
        identity = build_identity(user, auth)
      else
        first, last = split_name(auth)
        user = User.new(email_address: auth.info.email.strip.downcase,
                        first_name: first, last_name: last,
                        password_digest: SecureRandom.hex(32),
                        activated_at: Time.current)
        unless user.save
          return redirect_to new_session_path, alert: user.errors.full_messages.to_sentence
        end
        identity = build_identity(user, auth)
      end
    end

    user.update_column(:activated_at, Time.current) unless user.activated?

    merge_guest_cart(user)
    start_new_session_for(user)
    redirect_to after_authentication_url

  rescue => e
    Rails.logger.error "OauthCallbacksController error: #{e.message}"
    redirect_to new_session_path, alert: t(".alert_sign_in_failed")
  end

  def failure
    redirect_to new_session_path, alert: t(".alert", message: params[:message].humanize)
  end

  private

  def build_identity(user, auth)
    user.oauth_identities.create!(
      provider:           auth.provider,
      uid:                auth.uid,
      email:              auth.info.email,
      access_token:       auth.credentials&.token,
      refresh_token:      auth.credentials&.refresh_token,
      token_expires_at:   expires_at(auth),
      name_from_provider: auth.info.name
    )
  end

  def expires_at(auth)
    auth.credentials&.expires_at ? Time.at(auth.credentials.expires_at) : nil
  end

  def split_name(auth)
    if auth.provider == "apple" && auth.info.respond_to?(:first_name) && auth.info.first_name.present?
      return auth.info.first_name, auth.info.last_name.presence || "User"
    end
    parts = auth.info.name.to_s.strip.split(" ", 2)
    [ parts[0].presence || "User", parts[1].presence || "User" ]
  end
end
