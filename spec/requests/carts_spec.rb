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

    context "when the cart contains a sold item" do
      let!(:listing) { create(:listing) }
      let!(:sold_listing) { create(:listing, state: :sold) }

      before do
        user.cart_items.create!(listing: listing)
        user.cart_items.create!(listing: sold_listing)
      end

      it "destroys the sold cart item" do
        expect { get cart_path }.to change { user.cart_items.count }.by(-1)
      end

      it "shows an alert mentioning the sold listing name" do
        get cart_path

        expect(response.body).to include("#{sold_listing.name} has been sold and removed from your cart.")
      end
    end

    context "when the cart contains multiple sold items" do
      let!(:sold_listing_1) { create(:listing, state: :sold) }
      let!(:sold_listing_2) { create(:listing, state: :sold) }

      before do
        user.cart_items.create!(listing: sold_listing_1)
        user.cart_items.create!(listing: sold_listing_2)
      end

      it "destroys all sold cart items" do
        expect { get cart_path }.to change { user.cart_items.count }.by(-2)
      end

      it "uses plural phrasing in the alert" do
        get cart_path

        expect(response.body).to include("have been sold and removed from your cart.")
      end
    end

    context "when the session has an active fixed discount code" do
      # subtotal = $20.00 (tax-exempt), discount = $5.00 fixed, total = $15.00
      let!(:listing) { create(:listing, price_cents: 2000, tax_exempt: true) }
      let!(:discount_code) { create(:discount_code, :active, amount_cents: 500) }

      before do
        user.cart_items.create!(listing: listing)
        post cart_discount_path, params: { discount_code: discount_code.key }
      end

      it "displays the discount code key" do
        get cart_path

        expect(response.body).to include(discount_code.key)
      end

      it "deducts the discount from the total" do
        get cart_path

        expect(response.body).to include("15.00")
      end
    end

    context "when the session has an active percentage discount code" do
      let!(:listing) { create(:listing, price_cents: 2000, tax_exempt: true) }
      let!(:discount_code) { create(:discount_code, :active, :percentage) }

      before do
        user.cart_items.create!(listing: listing)
        post cart_discount_path, params: { discount_code: discount_code.key }
      end

      it "displays the discount percentage" do
        # :percentage trait has amount_cents: 1500 → view renders (1500 / 100)% off = 15% off
        get cart_path

        expect(response.body).to include("15% off")
      end
    end

    context "when the session has a discount code that is no longer active" do
      let!(:discount_code) { create(:discount_code, :active) }

      before do
        post cart_discount_path, params: { discount_code: discount_code.key }
        discount_code.update_columns(start_at: 3.days.ago, end_at: 2.days.ago)
      end

      it "removes the discount code from the session" do
        get cart_path

        expect(session[:discount_code_id]).to be_nil
      end

      it "shows an alert including the code key" do
        get cart_path

        expect(response.body).to include(%(Discount code "#{discount_code.key}" is no longer active.))
      end
    end

    context "when the session references a discount code that no longer exists" do
      let!(:discount_code) { create(:discount_code, :active) }

      before do
        post cart_discount_path, params: { discount_code: discount_code.key }
        discount_code.destroy!
      end

      it "removes the discount code id from the session" do
        get cart_path

        expect(session[:discount_code_id]).to be_nil
      end

      it "shows an alert indicating the code is no longer valid" do
        get cart_path

        expect(response.body).to include("Your discount code is no longer valid.")
      end
    end

    context "when the fixed discount exceeds the pretax total" do
      # price_cents: 100, taxable → tax = ceil(15) = 15 cents, pretax_total = 115 cents
      # discount capped at pretax_total (115 cents), total = 0
      let!(:listing) { create(:listing, price_cents: 100, tax_exempt: false) }
      let!(:discount_code) { create(:discount_code, :active, amount_cents: 5000) }

      before do
        user.cart_items.create!(listing: listing)
        post cart_discount_path, params: { discount_code: discount_code.key }
      end

      it "floors the total at zero" do
        get cart_path

        # Tax is $0.15 so "$0.00" is unique to the Total row
        expect(response.body).to include("$0.00")
      end
    end

    context "when the session has an active delivery method" do
      # subtotal = $20.00 (tax-exempt), delivery = $15.00, total = $35.00
      let!(:listing) { create(:listing, price_cents: 2000, tax_exempt: true) }
      let!(:delivery_method) { create(:delivery_method, :paid) }

      before do
        user.cart_items.create!(listing: listing)
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }
      end

      it "displays the delivery method name" do
        get cart_path

        expect(response.body).to include(delivery_method.name)
      end

      it "adds the delivery cost to the total" do
        get cart_path

        expect(response.body).to include("35.00")
      end
    end

    context "when the session has a delivery method that is no longer active" do
      let!(:delivery_method) { create(:delivery_method) }

      before do
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }
        delivery_method.update!(active: false)
      end

      it "removes the delivery method from the session" do
        get cart_path

        expect(session[:delivery_method_id]).to be_nil
      end

      it "shows an alert" do
        get cart_path

        expect(response.body).to include("Your delivery method is no longer available.")
      end
    end

    context "when the session references a delivery method that no longer exists" do
      let!(:delivery_method) { create(:delivery_method) }

      before do
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }
        delivery_method.destroy!
      end

      it "removes the delivery method id from the session" do
        get cart_path

        expect(session[:delivery_method_id]).to be_nil
      end

      it "shows an alert" do
        get cart_path

        expect(response.body).to include("Your delivery method is no longer available.")
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
