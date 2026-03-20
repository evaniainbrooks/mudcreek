require "rails_helper"

RSpec.describe "Profiles::PaymentMethods", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /profile/payment-methods" do
    before do
      allow_any_instance_of(SquareCustomerService).to receive(:list_cards).and_return([])
    end

    it "returns 200" do
      get profile_payment_methods_page_path

      expect(response).to have_http_status(:ok)
    end

    context "when SquareCustomerService raises an error" do
      before do
        allow_any_instance_of(SquareCustomerService).to receive(:list_cards).and_raise(StandardError)
      end

      it "returns 200 (error is rescued inline)" do
        get profile_payment_methods_page_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get profile_payment_methods_page_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
