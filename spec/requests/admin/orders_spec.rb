require "rails_helper"

RSpec.describe "Admin::Orders", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "order_manager", description: "Manage orders").tap do |r|
      r.permissions.create!(resource: "Order", action: "index")
      r.permissions.create!(resource: "Order", action: "show")
      r.permissions.create!(resource: "Order", action: "update")
    end
  end

  let(:user) { create(:user, role: role) }
  let(:buyer) { create(:user) }
  let!(:order) { create(:order, user: buyer) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/orders" do
    it "returns 200" do
      get admin_orders_path

      expect(response).to have_http_status(:ok)
    end

    it "displays the order number" do
      get admin_orders_path

      expect(response.body).to include(order.number)
    end

    it "displays the buyer name" do
      get admin_orders_path

      expect(response.body).to include(buyer.name)
    end

    it "displays the buyer email" do
      get admin_orders_path

      expect(response.body).to include(buyer.email_address)
    end

    it "displays the order total" do
      get admin_orders_path

      expect(response.body).to include("11.50")
    end

    context "when there are multiple orders" do
      let!(:older_order) { create(:order, user: buyer, created_at: 2.days.ago) }
      let!(:newer_order) { create(:order, user: buyer, created_at: 1.day.ago) }

      it "shows newer orders before older ones" do
        get admin_orders_path

        expect(response.body.index(newer_order.number)).to be < response.body.index(older_order.number)
      end
    end

    context "when there are orders from multiple users" do
      let(:other_buyer) { create(:user) }
      let!(:other_order) { create(:order, user: other_buyer) }

      it "displays all orders regardless of buyer" do
        get admin_orders_path

        expect(response.body).to include(order.number)
        expect(response.body).to include(other_order.number)
      end
    end

    context "when requesting a turbo stream page" do
      before { create_list(:order, 25, user: buyer) }

      it "appends rows and replaces the sentinel" do
        get admin_orders_path

        next_url  = response.body[/data-url="([^"]+)"/, 1]
        next_page = URI.decode_www_form(URI.parse(next_url).query).to_h["page"]

        get admin_orders_path(page: next_page),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.content_type).to start_with("text/vnd.turbo-stream.html")
        expect(response.body).to include('action="append" target="admin-orders-tbody"')
        expect(response.body).to include('action="replace" target="sentinel"')
      end
    end

    context "filtering by email address" do
      let(:other_buyer) { create(:user) }
      let!(:other_order) { create(:order, user: other_buyer) }

      it "returns only orders matching the email" do
        get admin_orders_path, params: { q: { user_email_address_cont: buyer.email_address } }

        expect(response.body).to include(order.number)
        expect(response.body).not_to include(other_order.number)
      end

      it "returns no orders when no email matches" do
        get admin_orders_path, params: { q: { user_email_address_cont: "nobody@example.com" } }

        expect(response.body).not_to include(order.number)
        expect(response.body).not_to include(other_order.number)
      end
    end

    context "filtering by status" do
      let!(:paid_order) { create(:order, user: buyer, status: "paid") }

      it "returns only orders with the given status" do
        get admin_orders_path, params: { q: { status_eq: "paid" } }

        expect(response.body).to include(paid_order.number)
        expect(response.body).not_to include(order.number)
      end
    end

    context "filtering by date range" do
      let!(:old_order) { create(:order, user: buyer, created_at: 10.days.ago) }

      it "returns only orders on or after the from date" do
        get admin_orders_path, params: { q: { created_at_gteq: 5.days.ago.to_date } }

        expect(response.body).to include(order.number)
        expect(response.body).not_to include(old_order.number)
      end

      it "returns only orders on or before the to date" do
        get admin_orders_path, params: { q: { created_at_lteq: 5.days.ago.to_date } }

        expect(response.body).to include(old_order.number)
        expect(response.body).not_to include(order.number)
      end

      it "returns orders within the date range when both bounds are given" do
        inside  = create(:order, user: buyer, created_at: 3.days.ago)
        outside = create(:order, user: buyer, created_at: 20.days.ago)

        get admin_orders_path, params: { q: { created_at_gteq: 7.days.ago.to_date, created_at_lteq: 1.day.ago.to_date } }

        expect(response.body).to include(inside.number)
        expect(response.body).not_to include(outside.number)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_orders_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_orders", description: "No order access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_orders_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/orders/:number" do
    it "returns 200" do
      get admin_order_path(order)

      expect(response).to have_http_status(:ok)
    end

    it "displays the order number" do
      get admin_order_path(order)

      expect(response.body).to include(order.number)
    end

    it "displays the buyer name" do
      get admin_order_path(order)

      expect(response.body).to include(buyer.name)
    end

    it "displays the buyer email" do
      get admin_order_path(order)

      expect(response.body).to include(buyer.email_address)
    end

    it "displays the order total" do
      get admin_order_path(order)

      expect(response.body).to include("11.50")
    end

    context "when the order has items" do
      before do
        order.order_items.create!(name: "Test Widget", price_cents: 1000, listing_type: "sale")
      end

      it "displays the item name" do
        get admin_order_path(order)

        expect(response.body).to include("Test Widget")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_order_path(order)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) do
        Role.create!(name: "index_only_orders", description: "Index-only order access").tap do |r|
          r.permissions.create!(resource: "Order", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_order_path(order) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/orders/:number" do
    context "updating status" do
      it "changes the order status" do
        patch admin_order_path(order), params: { order: { status: "paid" } }

        expect(order.reload.status).to eq("paid")
      end

      it "redirects back to the order with a notice" do
        patch admin_order_path(order), params: { order: { status: "paid" } }

        expect(response).to redirect_to(admin_order_path(order))
        expect(flash[:notice]).to eq("Order updated.")
      end
    end

    context "updating admin notes" do
      it "persists the notes" do
        patch admin_order_path(order), params: { order: { admin_notes: "Handle with care." } }

        expect(order.reload.admin_notes).to eq("Handle with care.")
      end
    end

    context "updating the delivery address" do
      let(:address_params) do
        { street_address: "99 New St", city: "Ottawa", province: "ON", postal_code: "K1A 0A9", country: "CA" }
      end

      it "updates the address fields" do
        patch admin_order_path(order), params: { order: address_params }

        order.reload
        expect(order.street_address).to eq("99 New St")
        expect(order.city).to eq("Ottawa")
        expect(order.province).to eq("ON")
        expect(order.postal_code).to eq("K1A 0A9")
        expect(order.country).to eq("CA")
      end

      it "redirects back to the order with a notice" do
        patch admin_order_path(order), params: { order: address_params }

        expect(response).to redirect_to(admin_order_path(order))
        expect(flash[:notice]).to eq("Order updated.")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_order_path(order), params: { order: { status: "paid" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_orders", description: "Read-only order access").tap do |r|
          r.permissions.create!(resource: "Order", action: "index")
          r.permissions.create!(resource: "Order", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_order_path(order), params: { order: { status: "paid" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
