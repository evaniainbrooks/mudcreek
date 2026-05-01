# Strip subdomain from callback URL so all tenants share one registered redirect URI.
# The tenant key is saved to session in before_request_phase (below) so TenantResolution
# can resolve it on the callback request, which arrives at the root domain.
OmniAuth.config.full_host = lambda do |env|
  request = Rack::Request.new(env)
  port_part = request.port.in?([80, 443]) ? "" : ":#{request.port}"
  "#{request.scheme}://#{request.host.sub(/\A[^.]+\./, '')}#{port_part}"
end

OmniAuth.config.before_request_phase do |env|
  request = Rack::Request.new(env)
  subdomain = request.host.split(".").first if request.host.split(".").length > 2
  env["rack.session"][:tenant_key] = subdomain if subdomain.present?
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    (Rails.application.credentials.dig(:oauth, :google, :client_id) || ""),
    (Rails.application.credentials.dig(:oauth, :google, :client_secret) || ""),
    scope: "email,profile", prompt: "select_account"

  provider :facebook,
    (Rails.application.credentials.dig(:oauth, :facebook, :app_id) || ""),
    (Rails.application.credentials.dig(:oauth, :facebook, :app_secret) || ""),
    scope: "email,public_profile",
    info_fields: "email,name,first_name,last_name"

  apple = Rails.application.credentials.dig(:oauth, :apple) || {}
  provider :apple,
    (apple[:client_id] || ""),
    "",
    team_id: (apple[:team_id] || ""),
    key_id:  (apple[:key_id] || ""),
    pem:     (apple[:private_key] || ""),
    scope:   "name email"
end

OmniAuth.config.logger = Rails.logger
