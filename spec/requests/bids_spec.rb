require "rails_helper"

RSpec.describe "Bids", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user)    { create(:user) }
  let(:listing) { create(:listing, published: true) }
  let(:auction) { create(:auction, published: true, auto_approve: true, starts_at: 1.day.ago, ends_at: 1.day.from_now) }
  let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000, bid_increment_cents: 500) }

  let(:bid_path) { auction_auction_listing_bids_path(auction, auction_listing) }

  context "when unauthenticated" do
    it "redirects to sign-in" do
      post bid_path, params: { amount_cents: 1000 }

      expect(response).to redirect_to(new_session_path)
    end

    it "does not create a bid" do
      expect { post bid_path, params: { amount_cents: 1000 } }
        .not_to change { Bid.count }
    end
  end

  context "when authenticated" do
    before { post session_path, params: { email_address: user.email_address, password: "password" } }

    context "with a valid amount and no existing bids" do
      it "creates a bid" do
        expect { post bid_path, params: { amount_cents: 1000 } }
          .to change { Bid.count }.by(1)
      end

      it "creates an approved registration automatically" do
        expect { post bid_path, params: { amount_cents: 1000 } }
          .to change { AuctionRegistration.count }.by(1)

        expect(AuctionRegistration.last.state).to eq("approved")
      end

      it "redirects to the auction page" do
        post bid_path, params: { amount_cents: 1000 }

        expect(response).to redirect_to(auction_path(auction))
      end
    end

    context "when a competing bid was placed since page load" do
      before do
        other_user = create(:user)
        registration = AuctionRegistration.create!(auction: auction, user: other_user)
        auction_listing.bids.create!(auction_registration: registration, amount_cents: 2000)
      end

      it "does not create a bid when the submitted amount does not exceed the current bid" do
        expect { post bid_path, params: { amount_cents: 1000 } }
          .not_to change { Bid.count }
      end

      it "redirects to the auction page" do
        post bid_path, params: { amount_cents: 1000 }

        expect(response).to redirect_to(auction_path(auction))
      end
    end

    context "when the user is already the highest bidder" do
      before do
        registration = AuctionRegistration.find_or_create_by!(auction: auction, user: user)
        auction_listing.bids.create!(auction_registration: registration, amount_cents: 1000)
      end

      it "does not create another bid" do
        expect { post bid_path, params: { amount_cents: 1500 } }
          .not_to change { Bid.count }
      end

      it "redirects to the auction page" do
        post bid_path, params: { amount_cents: 1500 }

        expect(response).to redirect_to(auction_path(auction))
      end
    end

    context "when registration requires manual approval" do
      let(:auction) { create(:auction, published: true, auto_approve: false, starts_at: 1.day.ago, ends_at: 1.day.from_now) }

      before do
        AuctionRegistration.create!(auction: auction, user: user, state: :pending)
      end

      it "does not create a bid" do
        expect { post bid_path, params: { amount_cents: 1000 } }
          .not_to change { Bid.count }
      end

      it "redirects to the auction page" do
        post bid_path, params: { amount_cents: 1000 }

        expect(response).to redirect_to(auction_path(auction))
      end
    end
  end
end
