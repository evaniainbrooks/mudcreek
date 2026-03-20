require "rails_helper"

RSpec.describe "CartGuestInfo", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  describe "POST /cart_guest_info" do
    let(:valid_params) { { guest_info: { email: "guest@example.com", name: "Guest User" } } }

    it "stores the email in the session" do
      post cart_guest_info_path, params: valid_params

      expect(session[:guest_email]).to eq("guest@example.com")
    end

    it "stores the name in the session" do
      post cart_guest_info_path, params: valid_params

      expect(session[:guest_name]).to eq("Guest User")
    end

    it "strips whitespace from email and name" do
      post cart_guest_info_path, params: { guest_info: { email: "  guest@example.com  ", name: "  Guest  " } }

      expect(session[:guest_email]).to eq("guest@example.com")
      expect(session[:guest_name]).to eq("Guest")
    end

    it "redirects to the cart" do
      post cart_guest_info_path, params: valid_params

      expect(response).to redirect_to(cart_path)
    end

    it "sets a notice flash" do
      post cart_guest_info_path, params: valid_params

      expect(flash[:notice]).to be_present
    end

    context "when unauthenticated" do
      it "still succeeds (guest access is allowed)" do
        post cart_guest_info_path, params: valid_params

        expect(response).to redirect_to(cart_path)
      end
    end
  end
end
