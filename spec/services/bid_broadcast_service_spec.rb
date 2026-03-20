require "rails_helper"

RSpec.describe BidBroadcastService do
  let(:tenant)  { Tenant.create!(name: "Test", key: "test", default: true) }
  let(:auction) { create(:auction, starts_at: 1.hour.ago, ends_at: 1.hour.from_now) }
  let(:listing) { create(:listing) }
  let(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000) }
  let(:user)    { create(:user) }
  let(:schedule) do
    s = BidIncrementSchedule.create!(auction_id: nil)
    s.tiers.create!(min_amount_cents: 0, increment_cents: 500)
    s
  end
  let(:registration) { AuctionRegistration.create!(auction: auction, user: user, state: :approved) }
  let(:bid) { auction_listing.bids.create!(auction_registration: registration, amount_cents: 1000, state: :placed) }

  let(:mock_renderer) { instance_double(ActionController::Renderer) }

  before do
    Current.tenant = tenant
    schedule
    bid  # cascades: creates auction, listing, auction_listing, user, registration, bid

    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    allow(ApplicationController).to receive(:renderer).and_return(mock_renderer)
    allow(mock_renderer).to receive(:render).and_return("<div>html</div>")
  end

  def call(state: "placed", id: auction_listing.id)
    described_class.call("state" => state, "auction_listing_id" => id)
  end

  # ------------------------------------------------------------------ #
  describe ".call" do
    context "when state is not 'placed'" do
      it "does not broadcast anything" do
        expect(Turbo::StreamsChannel).not_to receive(:broadcast_replace_to)

        call(state: "cancelled")
      end
    end

    context "when auction_listing_id does not exist" do
      it "does not broadcast anything" do
        expect(Turbo::StreamsChannel).not_to receive(:broadcast_replace_to)

        call(id: 0)
      end
    end

    context "when state is 'placed' and auction listing exists" do
      it "sets Current.tenant from the auction" do
        call

        expect(Current.tenant).to eq(tenant)
      end

      it "broadcasts a listing card replacement to the auction stream" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
          auction,
          target: ActionView::RecordIdentifier.dom_id(auction_listing),
          html:   "<div>html</div>"
        )

        call
      end

      it "broadcasts a bid panel replacement to the auction listing stream" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
          auction_listing,
          target: ActionView::RecordIdentifier.dom_id(auction_listing, :bid_panel),
          html:   "<div>html</div>"
        )

        call
      end

      it "renders the listing card partial with correct locals" do
        expect(mock_renderer).to receive(:render).with(
          partial: "auctions/listing_card",
          locals: hash_including(auction: auction, registration: nil)
        ).and_return("<div>card</div>")

        call
      end

      it "renders the bid panel partial with correct locals" do
        expect(mock_renderer).to receive(:render).with(
          partial: "auction_listings/bid_panel",
          locals: hash_including(auction: auction, auction_listing: auction_listing,
                                 registration: nil, bidder_token: an_instance_of(String))
        ).and_return("<div>panel</div>")

        call
      end
    end

    context "renderer host selection" do
      context "when the tenant has no custom domain" do
        it "uses the default renderer without a custom host" do
          expect(mock_renderer).not_to receive(:new)

          call
        end
      end

      context "when the tenant has a custom domain" do
        before { tenant.update_column(:custom_domain, "shop.example.com") }

        it "creates a renderer scoped to the custom domain" do
          expect(mock_renderer).to receive(:new)
            .with("HTTP_HOST" => "shop.example.com")
            .at_least(:once)
            .and_return(mock_renderer)

          call
        end
      end
    end

    context "bid extension" do
      context "when the auction has no bidding extension (0)" do
        before { auction.update_column(:bidding_extension, 0) }

        it "does not change auction_listing ends_at" do
          original_ends_at = auction_listing.reload.ends_at

          call

          expect(auction_listing.reload.ends_at).to be_within(1.second).of(original_ends_at)
        end
      end

      context "when bidding_extension is set and bid lands within the window" do
        before do
          auction.update_column(:bidding_extension, 120)
          # 60s from now — inside the 120s extension window
          auction_listing.update_column(:ends_at, 60.seconds.from_now)
        end

        it "extends ends_at by the configured seconds" do
          original_ends_at = auction_listing.reload.ends_at

          call

          expect(auction_listing.reload.ends_at).to be_within(1.second).of(original_ends_at + 120.seconds)
        end

        it "increments extension_count" do
          expect { call }.to change { auction_listing.reload.extension_count }.by(1)
        end
      end

      context "when bidding_extension is set but bid lands outside the window" do
        before do
          auction.update_column(:bidding_extension, 30)
          # 5 minutes out — well outside the 30s extension window
          auction_listing.update_column(:ends_at, 5.minutes.from_now)
        end

        it "does not change ends_at" do
          original_ends_at = auction_listing.reload.ends_at

          call

          expect(auction_listing.reload.ends_at).to be_within(1.second).of(original_ends_at)
        end

        it "does not increment extension_count" do
          expect { call }.not_to change { auction_listing.reload.extension_count }
        end
      end
    end
  end
end
