require "rails_helper"

RSpec.describe AuctionReconcilerJob do
  include ActiveSupport::Testing::TimeHelpers
  include ActiveJob::TestHelper

  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:auction) { create(:auction, starts_at: 2.hours.ago, ends_at: 1.hour.ago) }
  let(:bidder)  { create(:user) }

  def make_listing(ends_at, state: :on_sale, reserve_cents: nil)
    listing = create(:listing, published: true, state: state)
    al = create(:auction_listing, auction: auction, listing: listing, reserve_price_cents: reserve_cents)
    al.update_column(:ends_at, ends_at)
    al
  end

  def place_bid(auction_listing, amount_cents)
    registration = AuctionRegistration.find_or_create_by!(auction: auction, user: bidder)
    registration.update_column(:state, "approved")
    bid = auction_listing.bids.build(auction_registration: registration, amount_cents: amount_cents)
    bid.save!(validate: false)
    bid
  end

  describe "#perform" do
    context "when a listing has ended with a winning bid" do
      let!(:al) { make_listing(2.minutes.ago) }
      before { place_bid(al, 1000) }

      it "marks the listing as sold" do
        described_class.new.perform(auction)

        expect(al.listing.reload.state).to eq("sold")
      end
    end

    context "when a listing has ended with no bids" do
      let!(:al) { make_listing(2.minutes.ago) }

      it "marks the listing as cancelled" do
        described_class.new.perform(auction)

        expect(al.listing.reload.state).to eq("cancelled")
      end
    end

    context "when a listing has ended with a reserve price not met" do
      let!(:al) { make_listing(2.minutes.ago, reserve_cents: 5000) }
      before { place_bid(al, 1000) }

      it "marks the listing as cancelled" do
        described_class.new.perform(auction)

        expect(al.listing.reload.state).to eq("cancelled")
      end
    end

    context "when a listing has ended and the reserve price is exactly met" do
      let!(:al) { make_listing(2.minutes.ago, reserve_cents: 1000) }
      before { place_bid(al, 1000) }

      it "marks the listing as sold" do
        described_class.new.perform(auction)

        expect(al.listing.reload.state).to eq("sold")
      end
    end

    context "when a listing has not ended yet" do
      let!(:al) { make_listing(1.hour.from_now) }

      it "does not change the listing state" do
        described_class.new.perform(auction)

        expect(al.listing.reload.state).to eq("on_sale")
      end
    end

    context "when a listing is already sold" do
      let!(:al) { make_listing(2.minutes.ago, state: :sold) }

      it "does not re-process already sold listings" do
        expect { described_class.new.perform(auction) }
          .not_to change { al.listing.reload.state }
      end
    end

    context "re-enqueue and reconciliation" do
      context "when future listings remain" do
        let!(:ended_al)  { make_listing(2.minutes.ago) }
        let!(:future_al) { make_listing(1.hour.from_now) }

        it "re-enqueues at the next listing end time" do
          expect {
            described_class.new.perform(auction)
          }.to have_enqueued_job(described_class).with(auction).at(future_al.ends_at)
        end

        it "does not mark the auction as reconciled" do
          described_class.new.perform(auction)

          expect(auction.reload).not_to be_reconciled
        end
      end

      context "when all listings have ended" do
        let!(:al1) { make_listing(5.minutes.ago) }
        let!(:al2) { make_listing(2.minutes.ago) }

        it "does not re-enqueue the job" do
          expect {
            described_class.new.perform(auction)
          }.not_to have_enqueued_job(described_class)
        end

        it "marks the auction as reconciled" do
          described_class.new.perform(auction)

          expect(auction.reload).to be_reconciled
        end
      end

      context "when there are no listings" do
        it "does not raise an error" do
          expect { described_class.new.perform(auction) }.not_to raise_error
        end

        it "marks the auction as reconciled" do
          described_class.new.perform(auction)

          expect(auction.reload).to be_reconciled
        end
      end
    end
  end
end
