module SquareClient
  ENVIRONMENT = Rails.env.production? ? "production" : "sandbox"

  def self.config
    Rails.application.credentials.square&.public_send(ENVIRONMENT)
  end

  def self.configured?
    config.present?
  end

  BASE_URLS = {
    "sandbox"    => "https://connect.squareupsandbox.com",
    "production" => "https://connect.squareup.com"
  }.freeze

  def self.client
    @client ||= Square::Client.new(
      token:    config.access_token,
      base_url: BASE_URLS.fetch(ENVIRONMENT)
    )
  end

  def self.application_id
    config.application_id
  end

  def self.location_id
    config.location_id
  end

  def self.webhook_signature_key
    config.webhook_signature_key
  end
end
