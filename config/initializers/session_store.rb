# Share the session cookie across all subdomains so the OAuth callback (which lands on
# the root domain) can read the tenant_key stored before the redirect to Google/etc.
Rails.application.config.session_store :cookie_store,
  key: "_mudcreek_session",
  domain: :all,
  tld_length: 1
