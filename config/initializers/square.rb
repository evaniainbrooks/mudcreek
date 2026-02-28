module SquareClient
  def self.client
    @client ||= Square::Client.new(
      access_token: Rails.application.credentials.square.access_token,
      environment: Rails.application.credentials.square.environment
    )
  end

  def self.location_id
    Rails.application.credentials.square.location_id
  end

  def self.application_id
    Rails.application.credentials.square.application_id
  end
end
