require "rails_helper"

RSpec.describe "Orders::Payments", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user)   { create(:user) }
  let!(:order) { create(:order, user: user, status: "pending", total_cents: 1150) }

  let(:payments_api) { instance_double("Square::PaymentsApi") }
  let(:mock_client)  { instance_double("Square::Client", payments: payments_api) }

  before do
    allow(SquareClient).to receive(:client).and_return(mock_client)
    allow(SquareClient).to receive(:location_id).and_return("test_location")
    allow(SquareClient).to receive(:application_id).and_return("test_app_id")
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  describe "POST /orders/:order_number/payment" do
    let(:payment_double) do
      double("Square::ApiResponse",
        success?: true,
        errors: nil,
        data: double(payment: double(id: "sq_payment_123"))
      )
    end

    before do
      allow(payments_api).to receive(:create_payment).and_return(payment_double)
    end

    context "when the order is pending and payment succeeds" do
      it "marks the order as paid" do
        post order_payment_path(order), params: { source_id: "tok_test" }

        expect(order.reload.status).to eq("paid")
      end

      it "stores the Square payment ID" do
        post order_payment_path(order), params: { source_id: "tok_test" }

        expect(order.reload.square_payment_id).to eq("sq_payment_123")
      end

      it "redirects with a success notice" do
        post order_payment_path(order), params: { source_id: "tok_test" }

        expect(response).to redirect_to(order_path(order))
        follow_redirect!
        expect(response.body).to include("Payment successful!")
      end
    end

    context "when the order is already paid" do
      before { order.update!(status: "paid") }

      it "redirects with an alert and does not call Square" do
        post order_payment_path(order), params: { source_id: "tok_test" }

        expect(payments_api).not_to have_received(:create_payment)
        expect(response).to redirect_to(order_path(order))
        follow_redirect!
        expect(response.body).to include("already been processed")
      end
    end

    context "when Square returns an error" do
      let(:payment_double) do
        double("Square::ApiResponse",
          success?: false,
          errors: [ double(detail: "Card declined.") ],
          data: nil
        )
      end

      it "keeps the order as pending" do
        post order_payment_path(order), params: { source_id: "tok_bad" }

        expect(order.reload.status).to eq("pending")
      end

      it "redirects with the Square error message" do
        post order_payment_path(order), params: { source_id: "tok_bad" }

        expect(response).to redirect_to(order_path(order))
        follow_redirect!
        expect(response.body).to include("Card declined.")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post order_payment_path(order), params: { source_id: "tok_test" }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
