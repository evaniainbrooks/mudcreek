require "rails_helper"

RSpec.describe ProxyBiddingService do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:auction)  { create(:auction, starts_at: 1.hour.ago, ends_at: 1.day.from_now) }
  let(:listing)  { create(:listing) }
  let!(:schedule) do
    s = BidIncrementSchedule.create!(auction_id: nil)
    s.tiers.create!(min_amount_cents: 0, increment_cents: 500)
    s
  end
  let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000) }

  let(:user_a)  { create(:user) }
  let(:user_b)  { create(:user) }
  let(:reg_a)   { AuctionRegistration.create!(auction: auction, user: user_a, state: :approved) }
  let(:reg_b)   { AuctionRegistration.create!(auction: auction, user: user_b, state: :approved) }

  def place_proxy(registration, max_cents)
    ProxyBid.create!(auction_listing: auction_listing, auction_registration: registration, max_bid_cents: max_cents)
  end

  describe ".resolve" do
    context "with no proxy bids" do
      it "does nothing" do
        expect { described_class.resolve(auction_listing) }.not_to change { Bid.count }
      end
    end

    context "with a single proxy bid and no existing bids" do
      before { place_proxy(reg_a, 5000) }

      it "places a bid at the starting bid amount" do
        described_class.resolve(auction_listing)

        bid = auction_listing.bids.placed.order(created_at: :desc).first
        expect(bid.amount_cents).to eq(1000)
        expect(bid.auction_registration).to eq(reg_a)
      end
    end

    context "with two competing proxy bids" do
      before do
        place_proxy(reg_a, 3000)
        place_proxy(reg_b, 5000)
      end

      it "places a bid for the higher proxy at one increment above the lower proxy" do
        described_class.resolve(auction_listing)

        bid = auction_listing.bids.placed.order(created_at: :desc).first
        expect(bid.auction_registration).to eq(reg_b)
        expect(bid.amount_cents).to eq(3500) # 3000 + 500 increment
      end
    end

    context "when the winner's max is exactly at the runner-up's level plus increment" do
      before do
        place_proxy(reg_a, 3000)
        place_proxy(reg_b, 3500) # runner_up 3000 + 500 = 3500 exactly
      end

      it "caps at the winner's max" do
        described_class.resolve(auction_listing)

        bid = auction_listing.bids.placed.order(created_at: :desc).first
        expect(bid.amount_cents).to eq(3500)
        expect(bid.auction_registration).to eq(reg_b)
      end
    end

    context "when winner's max is lower than runner-up + increment" do
      before do
        place_proxy(reg_a, 3000)
        place_proxy(reg_b, 3200) # less than 3000 + 500
      end

      it "caps at the winner's max" do
        described_class.resolve(auction_listing)

        bid = auction_listing.bids.placed.order(created_at: :desc).first
        expect(bid.amount_cents).to eq(3200)
        expect(bid.auction_registration).to eq(reg_b)
      end
    end

    context "with tied max bids — tiebreaker by earliest created_at" do
      before do
        proxy_a = place_proxy(reg_a, 5000)
        proxy_a.update_column(:created_at, 1.hour.ago)
        place_proxy(reg_b, 5000)
      end

      it "gives the win to the earlier proxy bid" do
        described_class.resolve(auction_listing)

        bid = auction_listing.bids.placed.order(created_at: :desc).first
        expect(bid.auction_registration).to eq(reg_a)
      end
    end

    context "when the listing is inactive" do
      before do
        place_proxy(reg_a, 5000)
        auction_listing.listing.update_column(:state, "sold")
      end

      it "does nothing" do
        expect { described_class.resolve(auction_listing) }.not_to change { Bid.count }
      end
    end

    context "when the winner already holds the bid at the correct amount" do
      before do
        place_proxy(reg_a, 5000)
        described_class.resolve(auction_listing) # places initial bid at 1000
      end

      it "does not place a duplicate bid" do
        expect { described_class.resolve(auction_listing) }.not_to change { Bid.count }
      end
    end

    context "when a manual bid is placed by a non-proxy holder" do
      let(:user_c)  { create(:user) }
      let(:reg_c)   { AuctionRegistration.create!(auction: auction, user: user_c, state: :approved) }

      before do
        place_proxy(reg_a, 5000)
        described_class.resolve(auction_listing) # reg_a wins at 1000

        # reg_c places a manual bid above the current bid
        manual = auction_listing.bids.build(auction_registration: reg_c, amount_cents: 1500)
        manual.proxy_placed = true
        manual.save!
      end

      it "advances reg_a's bid one increment above the manual bid" do
        described_class.resolve(auction_listing)

        bid = auction_listing.bids.placed.order(created_at: :desc).first
        expect(bid.auction_registration).to eq(reg_a)
        expect(bid.amount_cents).to eq(2000) # 1500 + 500
      end
    end
  end
end
