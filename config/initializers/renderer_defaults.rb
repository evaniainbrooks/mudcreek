# Configure ApplicationController.renderer with the correct host so that
# broadcasts from background jobs (e.g. AuctionReconcilerJob) generate
# absolute Active Storage URLs pointing to the right domain instead of
# the renderer's built-in default of "www.example.com".
Rails.application.config.after_initialize do
  opts = Rails.application.config.action_mailer.default_url_options || {}
  host = opts[:host]
  port = opts[:port]
  host_with_port = [ host, port ].compact.join(":") if host

  ApplicationController.renderer.defaults.merge!("HTTP_HOST" => host_with_port) if host_with_port
end
