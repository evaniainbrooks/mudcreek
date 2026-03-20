require "rails_helper"

RSpec.describe "CartAddresses", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }
  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  let(:address_params) do
    { street_address: "123 Main St", city: "Vancouver",
      province: "BC", postal_code: "V5K 0A1", country: "CA" }
  end

  describe "POST /cart_address" do
    it "creates a cart address for the user" do
      expect {
        post cart_address_path, params: { cart_address: address_params }
      }.to change { user.reload.cart_address }.from(nil)
    end

    it "persists the city on the cart address" do
      post cart_address_path, params: { cart_address: address_params }
      expect(user.reload.cart_address.city).to eq("Vancouver")
    end

    it "redirects to the cart with a notice" do
      post cart_address_path, params: { cart_address: address_params }
      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to eq("Delivery address saved.")
    end

    it "updates an existing cart address" do
      Address.create!(addressable: user, address_type: "cart", **address_params)
      post cart_address_path,
        params: { cart_address: address_params.merge(city: "Victoria") }
      expect(user.reload.cart_address.city).to eq("Victoria")
    end

    context "with also_save_as_default=1" do
      it "also creates a profile address" do
        expect {
          post cart_address_path,
            params: { cart_address: address_params.merge(also_save_as_default: "1") }
        }.to change { user.reload.address }.from(nil)
      end

      it "sets the profile address city" do
        post cart_address_path,
          params: { cart_address: address_params.merge(also_save_as_default: "1") }
        expect(user.reload.address.city).to eq("Vancouver")
      end
    end

    context "without also_save_as_default" do
      it "does not create a profile address" do
        post cart_address_path, params: { cart_address: address_params }
        expect(user.reload.address).to be_nil
      end
    end

    context "when unauthenticated" do
      before { delete session_path }
      it "saves the address to the session and redirects to the cart" do
        post cart_address_path, params: { cart_address: address_params }
        expect(response).to redirect_to(cart_path)
      end
    end
  end
end
