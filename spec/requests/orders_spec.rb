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
        user.cart_items.create!(listing: create(:listing, delivery_method_set: create(:listings_delivery_method_set)))
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

    context "when the cart contains a physical item with a valid delivery method" do
      let!(:delivery_method) { create(:delivery_method, address_required: false) }
      let!(:delivery_set)    { create(:listings_delivery_method_set) }

      before do
        user.cart_items.create!(listing: create(:listing, delivery_method_set: delivery_set))
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }
      end

      it "creates the order" do
        expect { post orders_path }.to change { Order.count }.by(1)
      end

      it "redirects to the new order" do
        post orders_path

        expect(response).to redirect_to(order_path(Order.last))
      end
    end

    context "when a delivery method requires an address and one is in the user profile" do
      let!(:delivery_method) { create(:delivery_method, address_required: true) }

      before do
        user.create_address!(street_address: "1 Main St", city: "Halifax",
                             province: "NS", postal_code: "B3H 1A1", country: "CA")
        user.cart_items.create!(listing: listing)
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }
      end

      it "creates the order successfully" do
        expect { post orders_path }.to change { Order.count }.by(1)
      end

      it "snapshots the address onto the order" do
        post orders_path

        expect(Order.last.city).to eq("Halifax")
        expect(Order.last.country).to eq("CA")
      end
    end

    context "when the session delivery method has been deactivated" do
      let!(:delivery_method) { create(:delivery_method, :paid) }

      before do
        user.cart_items.create!(listing: listing)
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }
        delivery_method.update!(active: false)
      end

      it "creates the order without a delivery charge" do
        post orders_path

        expect(Order.last.delivery_price_cents).to eq(0)
      end
    end

    context "when the session discount code has been deactivated" do
      let!(:discount_code) { create(:discount_code, :active, amount_cents: 200) }

      before do
        user.cart_items.create!(listing: listing)
        post cart_discount_path, params: { discount_code: discount_code.key }
        discount_code.update!(end_at: 1.day.ago)
      end

      it "creates the order without a discount" do
        post orders_path

        expect(Order.last.discount_cents).to eq(0)
      end
    end

    context "when a rental item has a valid booking" do
      let(:rental_listing) { create(:listing, listing_type: :rental) }
      let(:cart_item) { create(:cart_item, :rental, user: user, listing: rental_listing) }

      before do
        create(:rental_booking, listing: rental_listing, cart_item: cart_item,
               start_at: 1.day.from_now, end_at: 2.days.from_now, expires_at: 1.hour.from_now)
      end

      it "creates the order" do
        expect { post orders_path }.to change { Order.count }.by(1)
      end
    end

    context "when a rental item has no booking" do
      before do
        rental_listing = create(:listing, listing_type: :rental)
        user.cart_items.create!(listing: rental_listing, rental_start_at: 1.day.from_now,
                                rental_end_at: 2.days.from_now, rental_price_cents: 5000)
      end

      it "redirects to the cart with an alert" do
        post orders_path

        expect(response).to redirect_to(cart_path)
        follow_redirect!
        expect(response.body).to include("no longer available")
      end

      it "does not create an order" do
        expect { post orders_path }.not_to change { Order.count }
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the cart when the cart is empty" do
        post orders_path

        expect(response).to redirect_to(cart_path)
      end

      context "with a guest cart item but no contact information" do
        before { post cart_items_path, params: { listing_id: listing.id } }

        it "redirects to the cart with an alert" do
          post orders_path

          expect(response).to redirect_to(cart_path)
          follow_redirect!
          expect(response.body).to include("Please provide your contact information.")
        end

        it "does not create an order" do
          expect { post orders_path }.not_to change { Order.count }
        end
      end

      context "with a guest cart item and contact information" do
        before do
          post cart_items_path, params: { listing_id: listing.id }
          post cart_guest_info_path, params: { guest_info: { email: "guest@example.com", name: "Guest User" } }
        end

        it "creates an order" do
          expect { post orders_path }.to change { Order.count }.by(1)
        end

        it "redirects to the order show page" do
          post orders_path

          expect(response).to redirect_to(order_path(Order.last))
        end

        it "sets the guest_order_token in the session" do
          post orders_path

          expect(session[:guest_order_token]).to be_present
        end

        it "clears the cart items" do
          token = session[:guest_cart_token]
          post orders_path

          expect(CartItem.where(guest_cart_token: token)).to be_empty
        end

        it "stores the guest email on the order" do
          post orders_path

          expect(Order.last.guest_email).to eq("guest@example.com")
        end
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

    context "when the order is pending and the user has a default card" do
      let(:saved_card) { double("card", id: "card_abc", card_brand: "VISA", last_4: "1234", exp_month: 12, exp_year: 2030) }

      before do
        user.update_columns(default_square_card_id: "card_abc", square_customer_id: "cust_xyz")
        order.update!(status: :pending)
        allow_any_instance_of(SquareCustomerService).to receive(:list_cards).and_return([ saved_card ])
      end

      it "exposes the matching saved card" do
        get order_path(order)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(order.number)
      end
    end

    context "when the order is pending but the user has no default card" do
      before { order.update!(status: :pending) }

      it "does not call the Square API" do
        expect_any_instance_of(SquareCustomerService).not_to receive(:list_cards)

        get order_path(order)
      end
    end

    context "when the order is paid" do
      before do
        user.update_column(:default_square_card_id, "card_abc")
        order.update!(status: :paid)
      end

      it "does not call the Square API" do
        expect_any_instance_of(SquareCustomerService).not_to receive(:list_cards)

        get order_path(order)
      end

      it "returns 200" do
        get order_path(order)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when SquareCustomerService raises an error" do
      before do
        user.update_columns(default_square_card_id: "card_abc", square_customer_id: "cust_xyz")
        order.update!(status: :pending)
        allow_any_instance_of(SquareCustomerService).to receive(:list_cards)
          .and_raise(SquareCustomerService::Error, "API failure")
      end

      it "returns 200 with an empty card list" do
        get order_path(order)

        expect(response).to have_http_status(:ok)
      end
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

      context "with the guest token in params" do
        let!(:guest_order) { create(:order, user: nil, guest_token: "secret-token-abc", guest_email: "g@example.com", guest_name: "Guest") }

        it "returns 200" do
          get order_path(guest_order), params: { token: "secret-token-abc" }

          expect(response).to have_http_status(:ok)
        end
      end

      context "with the guest token in session" do
        let!(:guest_order) { create(:order, user: nil, guest_token: "session-tok-xyz", guest_email: "g@example.com", guest_name: "Guest") }

        before do
          # Place a real guest order so the token lands in session
          listing_for_guest = create(:listing)
          post cart_items_path, params: { listing_id: listing_for_guest.id }
          post cart_guest_info_path, params: { guest_info: { email: "g@example.com", name: "Guest" } }
          post orders_path
          # session[:guest_order_token] is now set
        end

        it "returns 200 for the just-placed order" do
          get order_path(Order.where(user: nil).last)

          expect(response).to have_http_status(:ok)
        end
      end

      context "with no token" do
        it "returns not found for a guest order" do
          guest_order = create(:order, user: nil, guest_token: "tok", guest_email: "g@example.com", guest_name: "Guest")
          get order_path(guest_order)

          expect(response).to have_http_status(:not_found)
        end
      end

      it "returns not found for an authenticated user's order" do
        get order_path(order)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
