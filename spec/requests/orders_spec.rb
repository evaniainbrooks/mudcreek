require "rails_helper"

RSpec.describe "Orders", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user)    { create(:user) }
  let(:listing) { create(:listing) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /orders" do
    context "when the cart is empty" do
      it "redirects to the cart with an alert" do
        post orders_path

        expect(response).to redirect_to(cart_path)
        follow_redirect!
        expect(response.body).to include("Your cart is empty.")
      end
    end

    context "when the cart contains a physical item but no delivery method is selected" do
      before do
        create(:delivery_method)
        user.cart_items.create!(listing: create(:listing, physical: true))
      end

      it "redirects to the cart with an alert" do
        post orders_path

        expect(response).to redirect_to(cart_path)
        follow_redirect!
        expect(response.body).to include("Please select a delivery method.")
      end
    end

    context "when the selected delivery method requires an address but none is on file" do
      let!(:delivery_method) { create(:delivery_method, address_required: true) }

      before do
        user.cart_items.create!(listing: listing)
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }
      end

      it "redirects to the cart with an alert" do
        post orders_path

        expect(response).to redirect_to(cart_path)
        follow_redirect!
        expect(response.body).to include("Please provide a delivery address.")
      end
    end

    context "with a valid cart and no active delivery methods" do
      before { user.cart_items.create!(listing: listing) }

      it "redirects to the new order with a notice" do
        post orders_path

        expect(response).to redirect_to(order_path(Order.last))
        follow_redirect!
        expect(response.body).to include("Your order has been placed!")
      end

      it "creates an order for the user" do
        expect { post orders_path }.to change { user.orders.count }.by(1)
      end

      it "clears the cart" do
        post orders_path

        expect(user.cart_items.reload).to be_empty
      end

      it "records the correct subtotal, tax, and total" do
        post orders_path

        order = Order.last
        expect(order.subtotal_cents).to eq(listing.price_cents)
        expect(order.tax_cents).to eq((listing.price_cents * SALES_TAX_RATE).ceil)
        expect(order.total_cents).to eq(order.subtotal_cents + order.tax_cents)
      end

      it "builds an order item for each cart item" do
        post orders_path

        expect(Order.last.order_items.count).to eq(1)
        expect(Order.last.order_items.first.name).to eq(listing.name)
      end
    end

    context "with a delivery method selected in session" do
      let!(:delivery_method) { create(:delivery_method, :paid, address_required: false) }

      before do
        user.cart_items.create!(listing: listing)
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }
      end

      it "includes delivery price in the order total" do
        post orders_path

        order = Order.last
        expect(order.delivery_price_cents).to eq(delivery_method.price_cents)
        expect(order.delivery_method_name).to eq(delivery_method.name)
      end

      it "clears the delivery method from the session" do
        post orders_path

        get cart_path
        expect(response.body).not_to include(delivery_method.name)
      end
    end

    context "with a discount code applied in session" do
      let!(:discount_code) { create(:discount_code, :active, amount_cents: 500) }

      before do
        user.cart_items.create!(listing: listing)
        post cart_discount_path, params: { discount_code: discount_code.key }
      end

      it "applies the discount to the order" do
        post orders_path

        expect(Order.last.discount_cents).to eq(500)
        expect(Order.last.discount_code_key).to eq(discount_code.key)
      end

      it "clears the discount code from the session" do
        post orders_path

        get cart_path
        expect(response.body).not_to include(discount_code.key)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post orders_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /orders/:number" do
    let!(:order) { create(:order, user: user) }

    it "returns 200" do
      get order_path(order)

      expect(response).to have_http_status(:ok)
    end

    it "displays the order number" do
      get order_path(order)

      expect(response.body).to include(order.number)
    end

    context "when the order belongs to another user" do
      let(:other_user)  { create(:user) }
      let(:other_order) { create(:order, user: other_user) }

      it "returns 404" do
        get order_path(other_order)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get order_path(order)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
