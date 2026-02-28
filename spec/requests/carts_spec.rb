require "rails_helper"

RSpec.describe "Carts", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /cart" do
    context "with an empty cart" do
      it "returns 200" do
        get cart_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "with items in the cart" do
      let!(:listing) { create(:listing, price_cents: 1000, tax_exempt: false) }
      let!(:listing_exempt) { create(:listing, price_cents: 2000, tax_exempt: true) }

      before do
        user.cart_items.create!(listing: listing)
        user.cart_items.create!(listing: listing_exempt)
      end

      it "returns 200" do
        get cart_path

        expect(response).to have_http_status(:ok)
      end

      it "includes the taxable listing's contribution in the subtotal" do
        get cart_path

        expect(response.body).to include("30.00")
      end

      it "applies sales tax only to non-exempt listings" do
        # taxable_cents = 1000, tax = ceil(1000 * 0.15) = 150
        get cart_path

        expect(response.body).to include("1.50")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get cart_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
