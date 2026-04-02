require "rails_helper"

RSpec.describe "Admin::Listings::StockMovements", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "inventory_manager", description: "Manage inventory").tap do |r|
      r.permissions.create!(resource: "Listing", action: "update")
    end
  end

  let(:user)    { create(:user, role: role) }
  let(:listing) { create(:listing, quantity: 5) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/listings/:listing_hashid/stock_movements" do
    let(:valid_params) do
      { listings_stock_movement: { quantity: 10, unit_price: "4.99", transacted_on: Date.today, notes: "First shipment" } }
    end

    context "with valid params" do
      it "creates a stock movement" do
        expect {
          post admin_listing_stock_movements_path(listing_hashid: listing.hashid), params: valid_params
        }.to change { listing.stock_movements.count }.by(1)
      end

      it "increments the listing quantity" do
        expect {
          post admin_listing_stock_movements_path(listing_hashid: listing.hashid), params: valid_params
        }.to change { listing.reload.quantity }.by(10)
      end

      it "redirects to the inventory tab" do
        post admin_listing_stock_movements_path(listing_hashid: listing.hashid), params: valid_params

        expect(response).to redirect_to(admin_listing_path(listing, anchor: "inventory-pane"))
      end
    end

    context "with invalid params (missing quantity)" do
      let(:invalid_params) do
        { listings_stock_movement: { quantity: "", transacted_on: Date.today } }
      end

      it "does not create a stock movement" do
        expect {
          post admin_listing_stock_movements_path(listing_hashid: listing.hashid), params: invalid_params
        }.not_to change { listing.stock_movements.count }
      end

      it "does not change the listing quantity" do
        expect {
          post admin_listing_stock_movements_path(listing_hashid: listing.hashid), params: invalid_params
        }.not_to change { listing.reload.quantity }
      end

      it "redirects to the inventory tab with an alert" do
        post admin_listing_stock_movements_path(listing_hashid: listing.hashid), params: invalid_params

        expect(response).to redirect_to(admin_listing_path(listing, anchor: "inventory-pane"))
        expect(flash[:alert]).to include("Quantity")
      end
    end

    context "when the listing does not exist" do
      it "returns 404" do
        post admin_listing_stock_movements_path(listing_hashid: "doesnotexist"), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_listing_stock_movements_path(listing_hashid: listing.hashid), params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "no_inventory", description: "No inventory access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_listing_stock_movements_path(listing_hashid: listing.hashid), params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/listings/:listing_hashid/stock_movements/:id" do
    let!(:movement) do
      listing.stock_movements.create!(
        kind: :stock_in, reason: :acquisition, quantity: 6, transacted_on: Date.today
      )
      listing.reload
      listing.stock_movements.last
    end

    it "destroys the stock movement" do
      expect {
        delete admin_listing_stock_movement_path(listing_hashid: listing.hashid, id: movement.id)
      }.to change { listing.stock_movements.count }.by(-1)
    end

    it "decrements the listing quantity" do
      expect {
        delete admin_listing_stock_movement_path(listing_hashid: listing.hashid, id: movement.id)
      }.to change { listing.reload.quantity }.by(-6)
    end

    it "redirects to the inventory tab" do
      delete admin_listing_stock_movement_path(listing_hashid: listing.hashid, id: movement.id)

      expect(response).to redirect_to(admin_listing_path(listing, anchor: "inventory-pane"))
    end

    context "when the movement belongs to a different listing" do
      let(:other_listing) { create(:listing) }
      let!(:other_movement) do
        other_listing.stock_movements.create!(
          kind: :stock_in, reason: :acquisition, quantity: 3, transacted_on: Date.today
        )
        other_listing.stock_movements.last
      end

      it "returns 404" do
        delete admin_listing_stock_movement_path(listing_hashid: listing.hashid, id: other_movement.id)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_listing_stock_movement_path(listing_hashid: listing.hashid, id: movement.id)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "no_inventory", description: "No inventory access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_listing_stock_movement_path(listing_hashid: listing.hashid, id: movement.id)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
