require "rails_helper"

RSpec.describe "Admin::AuctionListings", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "auction_manager", description: "Manage auctions").tap do |r|
      r.permissions.create!(resource: "AuctionListing", action: "create")
      r.permissions.create!(resource: "AuctionListing", action: "destroy")
      r.permissions.create!(resource: "AuctionListing", action: "reorder")
    end
  end

  let(:user)    { create(:user, role: role) }
  let(:auction) { create(:auction) }
  let(:listing) { create(:listing) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/auction_listings (bulk add)" do
    it "adds sale listings to the auction" do
      expect {
        post admin_auction_listings_path, params: { auction_id: auction.id, listing_ids: [listing.id] }
      }.to change(AuctionListing, :count).by(1)
    end

    it "redirects to the admin listings index" do
      post admin_auction_listings_path, params: { auction_id: auction.id, listing_ids: [listing.id] }

      expect(response).to redirect_to(admin_listings_path)
    end

    it "skips listings already assigned to an auction" do
      AuctionListing.create!(auction: auction, listing: listing)

      expect {
        post admin_auction_listings_path, params: { auction_id: auction.id, listing_ids: [listing.id] }
      }.not_to change(AuctionListing, :count)
    end

    it "skips rental listings" do
      rental = create(:listing, listing_type: "rental")

      expect {
        post admin_auction_listings_path, params: { auction_id: auction.id, listing_ids: [rental.id] }
      }.not_to change(AuctionListing, :count)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_auction_listings_path, params: { auction_id: auction.id, listing_ids: [listing.id] }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_auction_listings", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_auction_listings_path, params: { auction_id: auction.id, listing_ids: [listing.id] }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/auctions/:auction_hashid/auction_listings/:id" do
    let!(:auction_listing) { AuctionListing.create!(auction: auction, listing: listing) }

    it "removes the listing from the auction" do
      expect {
        delete admin_auction_auction_listing_path(auction, auction_listing)
      }.to change(AuctionListing, :count).by(-1)
    end

    it "redirects to the auction show page with a notice" do
      delete admin_auction_auction_listing_path(auction, auction_listing)

      expect(response).to redirect_to(admin_auction_path(auction))
      expect(flash[:notice]).to include("removed")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_auction_auction_listing_path(auction, auction_listing)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) { Role.create!(name: "no_auction_listings", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_auction_auction_listing_path(auction, auction_listing)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/auctions/:auction_hashid/auction_listings/reorder" do
    let!(:al1) { AuctionListing.create!(auction: auction, listing: listing) }
    let!(:al2) { AuctionListing.create!(auction: auction, listing: create(:listing)) }

    it "returns 200" do
      patch reorder_admin_auction_auction_listings_path(auction),
        params: { id: al2.id, position: 1 },
        as: :json

      expect(response).to have_http_status(:ok)
    end

    it "updates the position of the auction listing" do
      patch reorder_admin_auction_auction_listings_path(auction),
        params: { id: al2.id, position: 1 },
        as: :json

      expect(al2.reload.position).to eq(1)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch reorder_admin_auction_auction_listings_path(auction),
          params: { id: al1.id, position: 2 },
          as: :json

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
