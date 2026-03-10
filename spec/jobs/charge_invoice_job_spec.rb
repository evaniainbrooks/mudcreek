require "rails_helper"

RSpec.describe ChargeInvoiceJob, type: :job do
  let(:user) { create(:user) }
  let(:invoice) { create(:invoice, user: user, total_cents: 10_000, status: :unpaid) }

  let(:payments_api) { instance_double("Square::Payments::Client") }
  let(:mock_client)  { instance_double("Square::Client", payments: payments_api) }

  let(:payment_response) do
    double("response", payment: double(id: "sq_pay_abc"))
  end

  before do
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
    invoice  # force creation after tenant is set
    user.update_columns(
      square_customer_id: "cust_123",
      default_square_card_id: "card_456"
    )
    allow(SquareClient).to receive(:client).and_return(mock_client)
    allow(SquareClient).to receive(:location_id).and_return("loc_test")
  end

  context "when the invoice is already paid" do
    before { invoice.update!(status: :paid) }

    it "does not call the Square API" do
      expect(payments_api).not_to receive(:create)

      described_class.perform_now(invoice.id)
    end
  end

  context "when the user has no default card" do
    before { user.update_columns(default_square_card_id: nil) }

    it "does not call the Square API" do
      expect(payments_api).not_to receive(:create)

      described_class.perform_now(invoice.id)
    end

    it "leaves the invoice unpaid" do
      described_class.perform_now(invoice.id)

      expect(invoice.reload.status).to eq("unpaid")
    end
  end

  context "when payment succeeds" do
    before { allow(payments_api).to receive(:create).and_return(payment_response) }

    it "calls the Square API with the correct payment params" do
      expect(payments_api).to receive(:create).with(
        source_id:       "card_456",
        customer_id:     "cust_123",
        idempotency_key: "invoice-#{invoice.id}-#{invoice.number}",
        amount_money:    { amount: 10_000, currency: "CAD" },
        location_id:     "loc_test",
        reference_id:    invoice.number,
        note:            "Invoice #{invoice.number}"
      ).and_return(payment_response)

      described_class.perform_now(invoice.id)
    end

    it "marks the invoice as paid" do
      described_class.perform_now(invoice.id)

      expect(invoice.reload.status).to eq("paid")
    end

    it "stores the Square payment id" do
      described_class.perform_now(invoice.id)

      expect(invoice.reload.square_payment_id).to eq("sq_pay_abc")
    end

    it "clears any previous charge_error" do
      invoice.update_columns(charge_error: "Previous failure")

      described_class.perform_now(invoice.id)

      expect(invoice.reload.charge_error).to be_nil
    end
  end

  context "when Square raises a payment error" do
    let(:error_detail) { "Card declined." }

    before do
      error_body = { errors: [ { detail: error_detail } ] }.to_json
      allow(payments_api).to receive(:create)
        .and_raise(Square::Errors::ResponseError.new(error_body, code: 400))
    end

    it "does not mark the invoice as paid" do
      described_class.perform_now(invoice.id)

      expect(invoice.reload.status).to eq("unpaid")
    end

    it "persists the error detail on the invoice" do
      described_class.perform_now(invoice.id)

      expect(invoice.reload.charge_error).to eq("Card declined.")
    end

    it "sends the invoice email" do
      mail = double("mail", deliver_later: true)
      allow(InvoiceMailer).to receive(:invoice_generated).with(invoice).and_return(mail)

      expect(mail).to receive(:deliver_later)

      described_class.perform_now(invoice.id)
    end

    context "when the Square error body is not parseable JSON" do
      before do
        allow(payments_api).to receive(:create)
          .and_raise(Square::Errors::ResponseError.new("not json", code: 500))
      end

      it "falls back to a generic error message" do
        described_class.perform_now(invoice.id)

        expect(invoice.reload.charge_error).to eq("Payment failed.")
      end
    end
  end

  context "when an unexpected error is raised" do
    before do
      allow(payments_api).to receive(:create).and_raise(RuntimeError, "network timeout")
    end

    it "stores the error message on the invoice" do
      described_class.perform_now(invoice.id) rescue nil

      expect(invoice.reload.charge_error).to eq("network timeout")
    end

    it "re-raises the error" do
      expect { described_class.perform_now(invoice.id) }.to raise_error(RuntimeError, "network timeout")
    end
  end
end
