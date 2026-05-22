class Webhooks::DropboxSignController < ActionController::Base
  skip_before_action :verify_authenticity_token

  SIGNED_EVENT = "signature_request_signed"

  def create
    payload = request.body.read

    unless valid_signature?(payload)
      head :unauthorized and return
    end

    # Dropbox Sign sends the event JSON as form param "json"
    event = JSON.parse(params[:json] || payload)

    if event.dig("event", "event_type") == SIGNED_EVENT
      HandleDropboxSignEventJob.perform_later(event)
    end

    # Dropbox Sign requires this exact response body
    render plain: "Hello API Event Received"
  end

  private

  def valid_signature?(payload)
    api_key = Rails.application.credentials.dropbox_sign&.api_key
    return false if api_key.blank?

    event_hash = params.dig(:json) ? JSON.parse(params[:json]).dig("event", "event_hash") : nil
    return false if event_hash.blank?

    expected = OpenSSL::HMAC.hexdigest("SHA256", api_key, payload)
    ActiveSupport::SecurityUtils.secure_compare(expected, event_hash)
  end
end
