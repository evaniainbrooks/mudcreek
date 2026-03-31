require "rails_helper"

RSpec.describe "Admin::Listings", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:role) do
    Role.create!(name: "listings_index", description: "View listings").tap do |r|
      r.permissions.create!(resource: "Listing", action: "index")
      r.permissions.create!(resource: "Listing", action: "create")
    end
  end
  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/listings/new" do
    it "returns 200" do
      get new_admin_listing_path

      expect(response).to have_http_status(:ok)
    end

    context "when the listing_variants feature is enabled" do
      before { Current.tenant.update!(features: { listing_variants: true }) }

      it "returns 200 without raising a routing error for the unsaved listing" do
        get new_admin_listing_path

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /admin/listings — auction_assigned filter" do
    let!(:assigned)   { create(:listing) }
    let!(:unassigned) { create(:listing) }
    let!(:auction)    { create(:auction) }

    before { create(:auction_listing, auction: auction, listing: assigned) }

    context "when filtering by auction_assigned=true" do
      it "returns only listings assigned to an auction" do
        get admin_listings_path, params: { q: { auction_assigned: true } }

        expect(response.body).to include(assigned.name)
        expect(response.body).not_to include(unassigned.name)
      end
    end

    context "when filtering by auction_assigned=false" do
      it "returns only listings not assigned to an auction" do
        get admin_listings_path, params: { q: { auction_assigned: false } }

        expect(response.body).not_to include(assigned.name)
        expect(response.body).to include(unassigned.name)
      end
    end

    context "when no auction_assigned filter is applied" do
      it "returns all listings" do
        get admin_listings_path

        expect(response.body).to include(assigned.name)
        expect(response.body).to include(unassigned.name)
      end
    end
  end
end
