require "rails_helper"

RSpec.describe AddListingsToAuctionService do
  let(:auction)  { double("Auction") }
  let(:service)  { described_class.new(auction: auction, listings: listings, starting_bid: starting_bid, listing_state: listing_state) }
  let(:listing_state) { nil }

  before do
    stub_const("AuctionListing", class_double("AuctionListing"))
  end

  describe ".call" do
    let(:listing)      { double("Listing", has_variants?: false, price_cents: 1000) }
    let(:listings)     { [listing] }
    let(:starting_bid) { "full" }

    it "delegates to a new instance" do
      allow(AuctionListing).to receive(:create!)
      expect(described_class).to receive(:new).with(
        auction: auction,
        listings: listings,
        starting_bid: starting_bid,
        listing_state: nil
      ).and_call_original

      described_class.call(auction: auction, listings: listings, starting_bid: starting_bid)
    end
  end

  describe "#call" do
    subject(:call) { service.call }

    context "with a plain listing (no variants)" do
      let(:listing)      { double("Listing", has_variants?: false, price_cents: 2000) }
      let(:listings)     { [listing] }
      let(:starting_bid) { "full" }

      it "creates one AuctionListing for the listing" do
        expect(AuctionListing).to receive(:create!).with(
          auction: auction,
          listing: listing,
          starting_bid_cents: 2000
        )

        call
      end

      it "does not call update_column when listing_state is nil" do
        allow(AuctionListing).to receive(:create!)
        expect(listing).not_to receive(:update_column)

        call
      end

      context "when listing_state is provided" do
        let(:listing_state) { "sold" }

        it "updates the listing state after creation" do
          allow(AuctionListing).to receive(:create!)
          expect(listing).to receive(:update_column).with(:state, "sold")

          call
        end

        it "does not update listing state when create! raises RecordInvalid" do
          allow(AuctionListing).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(AuctionListing))
          expect(listing).not_to receive(:update_column)

          call
        end

        it "does not update listing state when create! raises RecordNotUnique" do
          allow(AuctionListing).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
          expect(listing).not_to receive(:update_column)

          call
        end
      end
    end

    context "with a listing that has variants" do
      let(:variant_a)    { double("Variant", effective_price_cents: 500) }
      let(:variant_b)    { double("Variant", effective_price_cents: 800) }
      let(:listing)      { double("Listing", has_variants?: true, variants: [variant_a, variant_b]) }
      let(:listings)     { [listing] }
      let(:starting_bid) { "full" }

      it "creates one AuctionListing per variant" do
        expect(AuctionListing).to receive(:create!).with(
          auction: auction, listing: listing, variant: variant_a, starting_bid_cents: 500
        )
        expect(AuctionListing).to receive(:create!).with(
          auction: auction, listing: listing, variant: variant_b, starting_bid_cents: 800
        )

        call
      end

      it "skips a variant that raises RecordInvalid and continues with the rest" do
        allow(AuctionListing).to receive(:create!).with(hash_including(variant: variant_a))
          .and_raise(ActiveRecord::RecordInvalid.new(AuctionListing))
        expect(AuctionListing).to receive(:create!).with(hash_including(variant: variant_b))

        call
      end

      it "skips a variant that raises RecordNotUnique and continues with the rest" do
        allow(AuctionListing).to receive(:create!).with(hash_including(variant: variant_a))
          .and_raise(ActiveRecord::RecordNotUnique)
        expect(AuctionListing).to receive(:create!).with(hash_including(variant: variant_b))

        call
      end

      context "when listing_state is provided" do
        let(:listing_state) { "archived" }

        it "updates listing state even when some variants are skipped" do
          allow(AuctionListing).to receive(:create!).with(hash_including(variant: variant_a))
            .and_raise(ActiveRecord::RecordNotUnique)
          allow(AuctionListing).to receive(:create!).with(hash_including(variant: variant_b))
          expect(listing).to receive(:update_column).with(:state, "archived")

          call
        end
      end
    end

    context "starting_bid computation" do
      let(:listing)  { double("Listing", has_variants?: false, price_cents: 1000) }
      let(:listings) { [listing] }

      before { allow(listing).to receive(:update_column) }

      {
        "50"     => 500,
        "10"     => 100,
        "dollar" => 100,
        "full"   => 1000,
        nil      => 1000
      }.each do |option, expected_cents|
        it "computes #{expected_cents} cents for starting_bid=#{option.inspect}" do
          expect(AuctionListing).to receive(:create!).with(hash_including(starting_bid_cents: expected_cents))

          described_class.new(
            auction: auction,
            listings: listings,
            starting_bid: option
          ).call
        end
      end

      it "rounds up for the 50% option on an odd price" do
        odd_listing = double("Listing", has_variants?: false, price_cents: 999)
        expect(AuctionListing).to receive(:create!).with(hash_including(starting_bid_cents: 500))

        described_class.new(auction: auction, listings: [odd_listing], starting_bid: "50").call
      end
    end

    context "with multiple listings" do
      let(:listing_a)    { double("ListingA", has_variants?: false, price_cents: 100) }
      let(:listing_b)    { double("ListingB", has_variants?: false, price_cents: 200) }
      let(:listings)     { [listing_a, listing_b] }
      let(:starting_bid) { "full" }

      it "processes every listing" do
        expect(AuctionListing).to receive(:create!).with(hash_including(listing: listing_a))
        expect(AuctionListing).to receive(:create!).with(hash_including(listing: listing_b))

        call
      end
    end
  end
end
