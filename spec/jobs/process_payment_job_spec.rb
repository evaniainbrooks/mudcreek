require "rails_helper"

RSpec.describe ProcessPaymentJob, type: :job do
  let(:user)  { create(:user) }
  let(:order) { create(:order, user: user, status: "pending", total_cents: 1150) }

  let(:payments_api) { instance_double("Square::Payments::Client") }
  let(:mock_client)  { instance_double("Square::Client", payments: payments_api) }

  before do
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
    order  # force creation after tenant is set
    allow(SquareClient).to receive(:client).and_return(mock_client)
    allow(SquareClient).to receive(:location_id).and_return("test_location")
  end

  let(:payment_response) do
    double("response", payment: double(id: "sq_payment_123"))
  end

  context "when payment succeeds" do
    before { allow(payments_api).to receive(:create).and_return(payment_response) }

    it "marks the order as paid" do
      described_class.perform_now(order.id, "tok_test")
      expect(order.reload.status).to eq("paid")
    end

    it "stores the Square payment ID" do
      described_class.perform_now(order.id, "tok_test")
      expect(order.reload.square_payment_id).to eq("sq_payment_123")
    end

    it "broadcasts a redirect action to the order stream" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_action_to).with(
        "order_payment_#{order.id}",
        action: "redirect",
        target: a_string_including(order.number)
      )
      described_class.perform_now(order.id, "tok_test")
    end
  end

  context "when Square raises a payment error" do
    before do
      error_body = { errors: [ { detail: "Card declined." } ] }.to_json
      allow(payments_api).to receive(:create)
        .and_raise(Square::Errors::ResponseError.new(error_body, code: 400))
    end

    it "keeps the order as pending" do
      described_class.perform_now(order.id, "tok_bad")
      expect(order.reload.status).to eq("pending")
    end

    it "broadcasts an error replacement to the payment card" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "order_payment_#{order.id}",
        target: "payment-card",
        partial: "orders/payment_error",
        locals: { order: order, error: "Card declined." }
      )
      described_class.perform_now(order.id, "tok_bad")
    end
  end

  context "when the order is already paid" do
    before { order.update!(status: "paid") }

    it "skips the Square API call" do
      expect(payments_api).not_to receive(:create)
      described_class.perform_now(order.id, "tok_test")
    end
  end
end
