require "rails_helper"

RSpec.describe "Admin::Bids", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:role) do
    Role.create!(name: "bid_manager", description: "Manage bids").tap do |r|
      r.permissions.create!(resource: "Listing", action: "show")
      r.permissions.create!(resource: "Bid", action: "update")
    end
  end
  let(:user)    { create(:user, role: role) }
  let(:auction) { create(:auction, starts_at: 1.day.ago, ends_at: 1.day.from_now) }
  let(:listing) { create(:listing) }
  let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing) }
  let(:bidder)  { create(:user) }
  let(:registration) { AuctionRegistration.create!(auction: auction, user: bidder, state: :approved) }
  let!(:bid) { auction_listing.bids.create!(auction_registration: registration, amount_cents: 1000) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/listings/:hashid — bids tab" do
    it "shows the bids count badge" do
      get admin_listing_path(listing)

      expect(response.body).to include("Bids")
    end

    it "shows the bidder's email" do
      get admin_listing_path(listing)

      expect(response.body).to include(bidder.email_address)
    end

    it "shows the bid amount" do
      get admin_listing_path(listing)

      expect(response.body).to include("$10.00")
    end

    context "when the listing has no auction listing" do
      let(:listing) { create(:listing) }
      let!(:auction_listing) { nil }
      let!(:bid) { nil }

      it "does not show the bids tab" do
        get admin_listing_path(listing)

        expect(response.body).not_to include("bids-pane")
      end
    end
  end

  describe "PATCH /admin/bids/:id" do
    context "cancelling a placed bid" do
      it "transitions the bid to cancelled" do
        patch admin_bid_path(bid), params: { state: "cancelled" }

        expect(bid.reload).to be_cancelled
      end

      it "redirects to the listing with a notice" do
        patch admin_bid_path(bid), params: { state: "cancelled" }

        expect(response).to redirect_to(admin_listing_path(listing))
        expect(flash[:notice]).to eq("Bid marked as cancelled.")
      end
    end

    context "restoring a cancelled bid" do
      let!(:bid) { auction_listing.bids.create!(auction_registration: registration, amount_cents: 1000, state: :cancelled) }

      it "transitions the bid to placed" do
        patch admin_bid_path(bid), params: { state: "placed" }

        expect(bid.reload).to be_placed
      end

      it "redirects to the listing with a notice" do
        patch admin_bid_path(bid), params: { state: "placed" }

        expect(response).to redirect_to(admin_listing_path(listing))
        expect(flash[:notice]).to eq("Bid marked as placed.")
      end
    end

    context "with an invalid state" do
      it "does not change the bid state" do
        expect {
          patch admin_bid_path(bid), params: { state: "invalid" }
        }.not_to change { bid.reload.state }
      end

      it "redirects to the listing with an alert" do
        patch admin_bid_path(bid), params: { state: "invalid" }

        expect(response).to redirect_to(admin_listing_path(listing))
        expect(flash[:alert]).to eq("Invalid state.")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_bid_path(bid), params: { state: "cancelled" }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Listing", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_bid_path(bid), params: { state: "cancelled" }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
