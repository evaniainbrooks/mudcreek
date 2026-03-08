require "rails_helper"

RSpec.describe "Orders::Payments", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  let(:user)   { create(:user) }
  let!(:order) { create(:order, user: user, status: "pending", total_cents: 1150) }

  describe "POST /orders/:order_number/payment" do
    context "when the order is pending" do
      it "enqueues ProcessPaymentJob" do
        expect {
          post order_payment_path(order), params: { source_id: "tok_test" },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to have_enqueued_job(ProcessPaymentJob).with(anything, "tok_test", nil)
      end

      it "responds with a turbo stream showing the processing state" do
        post order_payment_path(order), params: { source_id: "tok_test" },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to include("turbo-stream")
        expect(response.body).to include("payment-card")
        expect(response.body).to include("Processing")
      end

      it "does not change the order status synchronously" do
        post order_payment_path(order), params: { source_id: "tok_test" }
        expect(order.reload.status).to eq("pending")
      end

      it "redirects for plain HTML requests" do
        post order_payment_path(order), params: { source_id: "tok_test" }
        expect(response).to redirect_to(order_path(order))
      end
    end

    context "when the order is already paid" do
      before { order.update!(status: "paid") }

      it "redirects with an alert and does not enqueue a job" do
        expect {
          post order_payment_path(order), params: { source_id: "tok_test" }
        }.not_to have_enqueued_job(ProcessPaymentJob)

        expect(response).to redirect_to(order_path(order))
        follow_redirect!
        expect(response.body).to include("already been processed")
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
