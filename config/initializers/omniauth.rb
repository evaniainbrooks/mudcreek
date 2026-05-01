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
