require "rails_helper"

RSpec.describe "ProxyBids", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user)    { create(:user) }
  let(:listing) { create(:listing, published: true) }
  let(:auction) { create(:auction, published: true, auto_approve: true, starts_at: 1.day.ago, ends_at: 1.day.from_now) }
  let!(:schedule) do
    s = BidIncrementSchedule.create!(auction_id: nil)
    s.tiers.create!(min_amount_cents: 0, increment_cents: 500)
    s
  end
  let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000) }

  let(:proxy_bid_path) { auction_auction_listing_proxy_bids_path(auction, auction_listing) }

  context "when unauthenticated" do
    it "redirects to sign-in" do
      post proxy_bid_path, params: { max_bid: 20.00 }

      expect(response).to redirect_to(new_session_path)
    end

    it "does not create a proxy bid" do
      expect { post proxy_bid_path, params: { max_bid: 20.00 } }
        .not_to change { ProxyBid.count }
    end
  end

  context "when authenticated" do
    before { post session_path, params: { email_address: user.email_address, password: "password" } }

    context "with a valid max bid" do
      it "creates a proxy bid" do
        expect { post proxy_bid_path, params: { max_bid: 20.00 } }
          .to change { ProxyBid.count }.by(1)
      end

      it "triggers resolution and places a bid" do
        expect { post proxy_bid_path, params: { max_bid: 20.00 } }
          .to change { Bid.count }.by(1)
      end

      it "creates an approved registration automatically" do
        expect { post proxy_bid_path, params: { max_bid: 20.00 } }
          .to change { AuctionRegistration.count }.by(1)

        expect(AuctionRegistration.last.state).to eq("approved")
      end

      it "redirects to the auction page" do
        post proxy_bid_path, params: { max_bid: 20.00 }

        expect(response).to redirect_to(auction_path(auction))
      end
    end

    context "with a max below the minimum bid" do
      it "does not create a proxy bid" do
        expect { post proxy_bid_path, params: { max_bid: 5.00 } }
          .not_to change { ProxyBid.count }
      end

      it "redirects back" do
        post proxy_bid_path, params: { max_bid: 5.00 }

        expect(response).to redirect_to(auction_path(auction))
      end
    end

    context "when updating an existing proxy bid with a higher max" do
      before do
        reg = AuctionRegistration.find_or_create_by!(auction: auction, user: user)
        ProxyBid.create!(auction_listing: auction_listing, auction_registration: reg, max_bid_cents: 2000)
      end

      it "does not create a new proxy bid record" do
        expect { post proxy_bid_path, params: { max_bid: 30.00 } }
          .not_to change { ProxyBid.count }
      end

      it "updates the existing proxy bid's max" do
        post proxy_bid_path, params: { max_bid: 30.00 }

        reg = AuctionRegistration.find_by(auction: auction, user: user)
        expect(auction_listing.proxy_bids.find_by(auction_registration: reg).max_bid_cents).to eq(3000)
      end
    end

    context "when submitting a max that is not higher than the existing proxy" do
      before do
        reg = AuctionRegistration.find_or_create_by!(auction: auction, user: user)
        ProxyBid.create!(auction_listing: auction_listing, auction_registration: reg, max_bid_cents: 2000)
      end

      it "does not update the proxy bid" do
        expect { post proxy_bid_path, params: { max_bid: 15.00 } }
          .not_to change { ProxyBid.first.max_bid_cents }
      end

      it "redirects with an alert" do
        post proxy_bid_path, params: { max_bid: 15.00 }

        expect(response).to redirect_to(auction_path(auction))
      end
    end

    context "when registration requires manual approval" do
      let(:auction) { create(:auction, published: true, auto_approve: false, starts_at: 1.day.ago, ends_at: 1.day.from_now) }

      before do
        AuctionRegistration.create!(auction: auction, user: user, state: :pending)
      end

      it "does not create a proxy bid" do
        expect { post proxy_bid_path, params: { max_bid: 20.00 } }
          .not_to change { ProxyBid.count }
      end
    end

    context "bid resolution after proxy bid is set" do
      it "places a bid at the starting amount when there is no competition" do
        post proxy_bid_path, params: { max_bid: 50.00 }

        bid = auction_listing.bids.placed.order(created_at: :desc).first
        expect(bid.amount_cents).to eq(1000)
      end

      context "when a competing proxy bid already exists" do
        let(:other_user) { create(:user) }

        before do
          other_reg = AuctionRegistration.create!(auction: auction, user: other_user, state: :approved)
          ProxyBid.create!(auction_listing: auction_listing, auction_registration: other_reg, max_bid_cents: 3000)
          ProxyBiddingService.resolve(auction_listing)
        end

        it "places the winning bid at one increment above the runner-up's max" do
          post proxy_bid_path, params: { max_bid: 50.00 }

          bid = auction_listing.bids.placed.order(created_at: :desc).first
          expect(bid.amount_cents).to eq(3500) # runner-up max 3000 + increment 500
          reg = AuctionRegistration.find_by(auction: auction, user: user)
          expect(bid.auction_registration).to eq(reg)
        end

        it "does not place a bid when user's max is below the current bid" do
          expect { post proxy_bid_path, params: { max_bid: 12.00 } }
            .not_to change { Bid.count }
        end
      end

      context "when both proxies have the same max — tiebreaker by creation time" do
        let(:other_user) { create(:user) }

        before do
          other_reg = AuctionRegistration.create!(auction: auction, user: other_user, state: :approved)
          proxy = ProxyBid.create!(auction_listing: auction_listing, auction_registration: other_reg, max_bid_cents: 5000)
          proxy.update_column(:created_at, 1.hour.ago)
        end

        it "the earlier proxy bid wins" do
          post proxy_bid_path, params: { max_bid: 50.00 }

          bid = auction_listing.bids.placed.order(created_at: :desc).first
          other_reg = AuctionRegistration.find_by(auction: auction, user: other_user)
          expect(bid.auction_registration).to eq(other_reg)
          expect(bid.amount_cents).to eq(5000)
        end
      end

      context "updating a proxy max preserves created_at for tiebreaking" do
        it "does not change created_at when the max is raised" do
          post proxy_bid_path, params: { max_bid: 20.00 }
          reg = AuctionRegistration.find_by(auction: auction, user: user)
          original_created_at = auction_listing.proxy_bids.find_by(auction_registration: reg).created_at

          post proxy_bid_path, params: { max_bid: 40.00 }

          expect(auction_listing.proxy_bids.find_by(auction_registration: reg).created_at).to eq(original_created_at)
        end
      end
    end
  end
end

RSpec.describe "Manual bids trigger proxy counter-bids", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:proxy_holder) { create(:user) }
  let(:manual_bidder) { create(:user) }
  let(:listing) { create(:listing, published: true) }
  let(:auction) { create(:auction, published: true, auto_approve: true, starts_at: 1.day.ago, ends_at: 1.day.from_now) }
  let!(:schedule) do
    s = BidIncrementSchedule.create!(auction_id: nil)
    s.tiers.create!(min_amount_cents: 0, increment_cents: 500)
    s
  end
  let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000) }

  let(:bid_path) { auction_auction_listing_bids_path(auction, auction_listing) }

  before do
    proxy_reg = AuctionRegistration.create!(auction: auction, user: proxy_holder, state: :approved)
    ProxyBid.create!(auction_listing: auction_listing, auction_registration: proxy_reg, max_bid_cents: 3000)
    ProxyBiddingService.resolve(auction_listing) # proxy holder holds bid at $10

    post session_path, params: { email_address: manual_bidder.email_address, password: "password" }
  end

  it "places a counter-bid for the proxy holder when a manual bid is submitted" do
    post bid_path, params: { amount_cents: 1500 }

    bids = auction_listing.bids.placed.order(amount_cents: :desc)
    expect(bids.first.amount_cents).to eq(2000) # proxy counter: 1500 + 500
    proxy_reg = AuctionRegistration.find_by(auction: auction, user: proxy_holder)
    expect(bids.first.auction_registration).to eq(proxy_reg)
  end

  it "does not counter-bid when the manual bid exceeds the proxy holder's max" do
    post bid_path, params: { amount_cents: 3500 }

    # manual bid is invalid (wrong amount), no counter should fire
    expect(auction_listing.bids.placed.order(amount_cents: :desc).first.amount_cents).to eq(1000)
  end

  context "when the manual bid is at the proxy holder's max" do
    it "proxy holder wins at their max" do
      manual_reg = AuctionRegistration.create!(auction: auction, user: manual_bidder, state: :approved)
      competing_bid = auction_listing.bids.build(auction_registration: manual_reg, amount_cents: 2500)
      competing_bid.proxy_placed = true
      competing_bid.save!

      ProxyBiddingService.resolve(auction_listing)

      top_bid = auction_listing.bids.placed.order(amount_cents: :desc).first
      proxy_reg = AuctionRegistration.find_by(auction: auction, user: proxy_holder)
      expect(top_bid.auction_registration).to eq(proxy_reg)
      expect(top_bid.amount_cents).to eq(3000)
    end
  end
end
