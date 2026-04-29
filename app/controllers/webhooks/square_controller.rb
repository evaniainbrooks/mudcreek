class Webhooks::SquareController < ActionController::Base
  include TenantResolution

  skip_before_action :verify_authenticity_token

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
    payment_data = event.dig("data", "object", "payment")
    reference_id = payment_data["reference_id"]

    order = reference_id.present? ? Order.unscoped.find_by(number: reference_id) : nil

    if order.nil?
      SyncSquarePosPaymentService.call(payment_data: payment_data, tenant: Current.tenant) if event["type"] == "payment.completed"
      return
    end

    # Find or create the transaction for reconciliation
    transaction = order.transactions.find_by(square_payment_id: payment_data["id"])
    if transaction.nil? && event["type"] == "payment.completed"
      transaction = order.transactions.create!(
        amount_cents:    payment_data.dig("amount_money", "amount"),
        state:           :succeeded,
        square_payment_id: payment_data["id"],
        raw_response:    payment_data
      )
    end

    ActiveRecord::Base.transaction do
      # Lock the transaction if it exists
      transaction&.with_lock do
        case event["type"]
        when "payment.completed"
          transaction.update!(state: :succeeded, raw_response: payment_data) if transaction&.pending?

          order.with_lock { order.update!(status: :paid) if order.transactions.succeeded.exists? }
        when "payment.canceled"
          transaction.update!(state: :failed) if transaction&.pending?

          order.with_lock { order.update!(status: :cancelled) if order.pending? }
        end
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Webhook reconciliation failed: #{e.message}")
  end
end
