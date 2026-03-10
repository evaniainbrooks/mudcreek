require "rails_helper"

RSpec.describe BidPlacementService do
  # BidPlacementService is not wired to any controller. Its `listing`
  # parameter is expected to respond to #ends_at, #bids, and #id.
  # `extend_if_needed` issues a raw UPDATE via Listing.where, so we
  # stub that at the class level to keep specs DB-agnostic.

  let(:bid)     { double("Bid") }
  let(:bids)    { double("bids association", create!: bid) }
  let(:listing) { double("listing", id: 99, ends_at: 10.minutes.from_now, bids: bids) }
  let(:user)    { double("User") }
  let(:amount)  { 1500 }

  before do
    stub_const("Listing", class_double("Listing"))
    allow(Listing).to receive(:where).and_return(
      double("relation", where: double("relation", update_all: 0))
    )
  end

  describe ".call" do
    context "when the auction listing has already ended" do
      before { allow(listing).to receive(:ends_at).and_return(1.minute.ago) }

      it "raises AuctionEnded" do
        expect {
          described_class.call(listing: listing, user: user, amount: amount)
        }.to raise_error(BidPlacementService::AuctionEnded)
      end

      it "does not create a bid" do
        described_class.call(listing: listing, user: user, amount: amount) rescue nil

        expect(bids).not_to have_received(:create!)
      end
    end

    context "when the auction listing is still open" do
      it "creates a bid with the given user and amount" do
        expect(bids).to receive(:create!).with(user: user, amount: amount).and_return(bid)

        described_class.call(listing: listing, user: user, amount: amount)
      end

      it "returns the created bid" do
        result = described_class.call(listing: listing, user: user, amount: amount)

        expect(result).to eq(bid)
      end

      it "calls extend_if_needed with the listing" do
        expect(described_class).to receive(:extend_if_needed).with(listing)

        described_class.call(listing: listing, user: user, amount: amount)
      end
    end
  end

  describe ".extend_if_needed" do
    let(:inner_relation) { double("inner_relation") }
    let(:outer_relation) { double("outer_relation", where: inner_relation) }

    before do
      allow(Listing).to receive(:where).with(id: listing.id).and_return(outer_relation)
      allow(inner_relation).to receive(:update_all).and_return(0)
    end

    it "scopes the query to the listing's id" do
      expect(Listing).to receive(:where).with(id: listing.id).and_return(outer_relation)

      described_class.extend_if_needed(listing)
    end

    it "further filters to listings within the extension window" do
      expect(outer_relation).to receive(:where).with(/NOW\(\) >= ends_at/).and_return(inner_relation)

      described_class.extend_if_needed(listing)
    end

    it "issues an UPDATE for ends_at and extension_count" do
      expect(inner_relation).to receive(:update_all).with(a_string_matching(/ends_at.*extension_count/m))

      described_class.extend_if_needed(listing)
    end
  end
end
