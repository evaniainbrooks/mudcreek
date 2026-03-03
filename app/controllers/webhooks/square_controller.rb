class Webhooks::SquareController < ActionController::Base
  protect_from_forgery with: :null_session

  HANDLED_EVENTS = %w[payment.completed payment.canceled].freeze

  def create
    payload   = request.body.read
    signature = request.headers["X-Square-Hmacsha256-Signature"]

    unless valid_signature?(signature, request.original_url, payload)
      head :unauthorized and return
    end

    event = JSON.parse(payload)
    handle_event(event) if HANDLED_EVENTS.include?(event["type"])

    head :ok
  end

  private

  def valid_signature?(signature, url, body)
    return false if signature.blank?
    hmac     = OpenSSL::HMAC.digest("SHA256", SquareClient.webhook_signature_key, url + body)
    expected = Base64.strict_encode64(hmac)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  def handle_event(event)
    reference_id = event.dig("data", "object", "payment", "reference_id")
    return if reference_id.blank?

    order = Order.unscoped.find_by(number: reference_id)
    return unless order&.pending?

    case event["type"]
    when "payment.completed"
      order.update!(
        status:            "paid",
        square_payment_id: event.dig("data", "object", "payment", "id")
      )
    when "payment.canceled"
      order.update!(status: "cancelled")
    end
  end
end
