require "rails_helper"

RSpec.describe "Webhooks::Square", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:signature_key) { "test_webhook_key" }
  let!(:order) { create(:order, status: "pending") }
  let!(:transaction) { create(:transaction, state: :pending, order:, square_payment_id: "sq_pay_abc") }

  before do
    allow(SquareClient).to receive(:webhook_signature_key).and_return(signature_key)
  end

  def square_signature(url, body)
    hmac = OpenSSL::HMAC.digest("SHA256", signature_key, url + body)
    Base64.strict_encode64(hmac)
  end

  def post_webhook(payload, sig: nil)
    body = payload.to_json
    url  = "http://example.com/webhooks/square"
    sig  ||= square_signature(url, body)
    post webhooks_square_path,
      params: body,
      headers: {
        "Content-Type"                    => "application/json",
        "X-Square-Hmacsha256-Signature"   => sig
      }
  end

  def payment_event(type, reference_id: order.number, payment_id: "sq_pay_abc")
    {
      "type" => type,
      "data" => {
        "object" => {
          "payment" => {
            "amount_money" => { "amount" => 100_00 },
            "id"           => payment_id,
            "reference_id" => reference_id
          }
        }
      }
    }
  end

  def pos_payment_event(payment_id: "sq_pos_001")
    {
      "type" => "payment.completed",
      "data" => {
        "object" => {
          "payment" => {
            "amount_money" => { "amount" => 5000 },
            "id"           => payment_id
          }
        }
      }
    }
  end

  describe "POST /webhooks/square" do
    context "with an invalid signature" do
      it "returns 401" do
        post_webhook(payment_event("payment.completed"), sig: "bad_sig")

        expect(response).to have_http_status(:unauthorized)
      end

      it "does not change the order" do
        expect {
          post_webhook(payment_event("payment.completed"), sig: "bad_sig")
        }.not_to change { order.reload.status }
      end
    end

    context "with a valid signature and payment.completed" do
      it "returns 200" do
        post_webhook(payment_event("payment.completed"))

        expect(response).to have_http_status(:ok)
      end

      it "marks the order as paid" do
        post_webhook(payment_event("payment.completed"))

        expect(order.reload.status).to eq("paid")
      end

      it "stores the Square payment ID" do
        post_webhook(payment_event("payment.completed", payment_id: "sq_pay_abc"))

        expect(transaction.reload.square_payment_id).to eq("sq_pay_abc")
      end
    end

    context "with a valid signature and payment.canceled" do
      it "marks the order as cancelled" do
        post_webhook(payment_event("payment.canceled"))

        expect(order.reload.status).to eq("cancelled")
      end
    end

    context "with an unknown event type" do
      it "returns 200 and does not change the order" do
        expect {
          post_webhook(payment_event("payment.unknown_event"))
        }.not_to change { order.reload.status }

        expect(response).to have_http_status(:ok)
      end
    end

    context "with a POS payment (no reference_id)" do
      before { allow(SyncSquarePosPaymentService).to receive(:call) }

      it "returns 200" do
        post_webhook(pos_payment_event)

        expect(response).to have_http_status(:ok)
      end

      it "delegates to SyncSquarePosPaymentService" do
        post_webhook(pos_payment_event(payment_id: "sq_pos_001"))

        expect(SyncSquarePosPaymentService).to have_received(:call).with(
          payment_data: hash_including("id" => "sq_pos_001"),
          tenant:       be_a(Tenant)
        )
      end

      it "does not change any existing order" do
        expect {
          post_webhook(pos_payment_event)
        }.not_to change { order.reload.status }
      end
    end

    context "with payment.completed whose reference_id matches no order" do
      before { allow(SyncSquarePosPaymentService).to receive(:call) }

      it "delegates to SyncSquarePosPaymentService" do
        post_webhook(payment_event("payment.completed", reference_id: "MC-UNKNOWN0"))

        expect(SyncSquarePosPaymentService).to have_received(:call)
      end

      it "returns 200" do
        post_webhook(payment_event("payment.completed", reference_id: "MC-UNKNOWN0"))

        expect(response).to have_http_status(:ok)
      end
    end

    context "with payment.canceled for a POS payment (no matching order)" do
      it "returns 200 without calling SyncSquarePosPaymentService" do
        expect(SyncSquarePosPaymentService).not_to receive(:call)

        post_webhook(pos_payment_event.merge("type" => "payment.canceled"))

        expect(response).to have_http_status(:ok)
      end
    end

    context "idempotency — order already paid" do
      before { order.update!(status: "paid", square_payment_id: "existing_id") }

      it "does not overwrite the existing payment ID" do
        post_webhook(payment_event("payment.completed", payment_id: "new_id"))

        expect(order.reload.square_payment_id).to eq("existing_id")
      end

      it "returns 200" do
        post_webhook(payment_event("payment.completed"))

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
