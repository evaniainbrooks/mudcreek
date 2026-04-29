require "rails_helper"

RSpec.describe SyncSquareTransactionsJob, type: :job do
  let!(:tenant) { Tenant.create!(name: "Test", key: "test", default: true) }

  let(:payments_api) { instance_double("Square::Payments::Client") }
  let(:mock_client)  { instance_double("Square::Client", payments: payments_api) }

  before do
    Current.tenant = tenant
    allow(SquareClient).to receive(:client).and_return(mock_client)
    allow(SquareClient).to receive(:location_id).and_return("loc_test")
    allow(SyncSquarePosPaymentService).to receive(:call)
  end

  def mock_payment(id:, status: "COMPLETED", reference_id: nil)
    double("Payment",
      id:           id,
      status:       status,
      reference_id: reference_id,
      to_h:         { "id" => id, "status" => status, "reference_id" => reference_id, "amount_money" => { "amount" => 1000 } }
    )
  end

  def stub_payments_list(*payments)
    allow(payments_api).to receive(:list).and_return(payments)
  end

  describe "#perform" do
    context "with a completed POS payment (no reference_id)" do
      let(:pos_payment) { mock_payment(id: "sq_pos_1") }

      before { stub_payments_list(pos_payment) }

      it "calls SyncSquarePosPaymentService with the payment hash" do
        described_class.perform_now

        expect(SyncSquarePosPaymentService).to have_received(:call).with(
          payment_data: pos_payment.to_h,
          tenant:       tenant
        )
      end
    end

    context "with an app-originated payment (has reference_id)" do
      let(:app_payment) { mock_payment(id: "sq_app_1", reference_id: "MC-ABCDEF12") }

      before { stub_payments_list(app_payment) }

      it "does not call SyncSquarePosPaymentService" do
        described_class.perform_now

        expect(SyncSquarePosPaymentService).not_to have_received(:call)
      end
    end

    context "with a non-COMPLETED payment" do
      let(:pending_payment) { mock_payment(id: "sq_pend_1", status: "PENDING") }

      before { stub_payments_list(pending_payment) }

      it "does not call SyncSquarePosPaymentService" do
        described_class.perform_now

        expect(SyncSquarePosPaymentService).not_to have_received(:call)
      end
    end

    context "with a mix of POS and app payments" do
      let(:pos_payment) { mock_payment(id: "sq_pos_1") }
      let(:app_payment) { mock_payment(id: "sq_app_1", reference_id: "MC-ABCDEF12") }

      before { stub_payments_list(pos_payment, app_payment) }

      it "syncs only the POS payment" do
        described_class.perform_now

        expect(SyncSquarePosPaymentService).to have_received(:call).once
        expect(SyncSquarePosPaymentService).to have_received(:call).with(
          hash_including(payment_data: pos_payment.to_h)
        )
      end
    end

    context "when there are no payments" do
      before { stub_payments_list }

      it "does not call SyncSquarePosPaymentService" do
        described_class.perform_now

        expect(SyncSquarePosPaymentService).not_to have_received(:call)
      end
    end

    it "resets Current.tenant after completion" do
      stub_payments_list
      described_class.perform_now

      expect(Current.tenant).to be_nil
    end
  end
end
