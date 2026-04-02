require "rails_helper"

RSpec.describe "Admin::Listings::Acquisitions", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "inventory_manager", description: "Manage inventory").tap do |r|
      r.permissions.create!(resource: "Listings::Acquisition", action: "create")
      r.permissions.create!(resource: "Listings::Acquisition", action: "destroy")
    end
  end

  let(:user)    { create(:user, role: role) }
  let(:listing) { create(:listing, quantity: 5) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/listings/:listing_hashid/acquisitions" do
    let(:valid_params) do
      { listings_acquisition: { quantity: 10, unit_price: "4.99", acquired_on: Date.today, notes: "First shipment" } }
    end

    context "with valid params" do
      it "creates an acquisition" do
        expect {
          post admin_listing_acquisitions_path(listing_hashid: listing.hashid), params: valid_params
        }.to change { listing.acquisitions.count }.by(1)
      end

      it "increments the listing quantity" do
        expect {
          post admin_listing_acquisitions_path(listing_hashid: listing.hashid), params: valid_params
        }.to change { listing.reload.quantity }.by(10)
      end

      it "redirects to the inventory tab" do
        post admin_listing_acquisitions_path(listing_hashid: listing.hashid), params: valid_params

        expect(response).to redirect_to(admin_listing_path(listing, anchor: "inventory-pane"))
      end
    end

    context "with invalid params (missing quantity)" do
      let(:invalid_params) do
        { listings_acquisition: { quantity: "", acquired_on: Date.today } }
      end

      it "does not create an acquisition" do
        expect {
          post admin_listing_acquisitions_path(listing_hashid: listing.hashid), params: invalid_params
        }.not_to change { listing.acquisitions.count }
      end

      it "does not change the listing quantity" do
        expect {
          post admin_listing_acquisitions_path(listing_hashid: listing.hashid), params: invalid_params
        }.not_to change { listing.reload.quantity }
      end

      it "redirects to the inventory tab with an alert" do
        post admin_listing_acquisitions_path(listing_hashid: listing.hashid), params: invalid_params

        expect(response).to redirect_to(admin_listing_path(listing, anchor: "inventory-pane"))
        follow_redirect!
        expect(response.body).to include("Quantity")
      end
    end

    context "when the listing does not exist" do
      it "returns 404" do
        post admin_listing_acquisitions_path(listing_hashid: "doesnotexist"), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_listing_acquisitions_path(listing_hashid: listing.hashid), params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_inventory", description: "No inventory access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_listing_acquisitions_path(listing_hashid: listing.hashid), params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/listings/:listing_hashid/acquisitions/:id" do
    let!(:acquisition) do
      listing.acquisitions.create!(quantity: 6, acquired_on: Date.today)
      listing.reload
      listing.acquisitions.last
    end

    it "destroys the acquisition" do
      expect {
        delete admin_listing_acquisition_path(listing_hashid: listing.hashid, id: acquisition.id)
      }.to change { listing.acquisitions.count }.by(-1)
    end

    it "decrements the listing quantity" do
      expect {
        delete admin_listing_acquisition_path(listing_hashid: listing.hashid, id: acquisition.id)
      }.to change { listing.reload.quantity }.by(-6)
    end

    it "redirects to the inventory tab" do
      delete admin_listing_acquisition_path(listing_hashid: listing.hashid, id: acquisition.id)

      expect(response).to redirect_to(admin_listing_path(listing, anchor: "inventory-pane"))
    end

    context "when the acquisition belongs to a different listing" do
      let(:other_listing)  { create(:listing) }
      let!(:other_acquisition) do
        other_listing.acquisitions.create!(quantity: 3, acquired_on: Date.today)
        other_listing.acquisitions.last
      end

      it "returns 404" do
        delete admin_listing_acquisition_path(listing_hashid: listing.hashid, id: other_acquisition.id)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_listing_acquisition_path(listing_hashid: listing.hashid, id: acquisition.id)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) { Role.create!(name: "no_inventory", description: "No inventory access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_listing_acquisition_path(listing_hashid: listing.hashid, id: acquisition.id)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
