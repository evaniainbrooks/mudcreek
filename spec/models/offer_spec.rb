require "rails_helper"

RSpec.describe Offer, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:listing) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount_cents) }

    it "rejects an amount of zero" do
      offer = build(:offer, amount_cents: 0)

      expect(offer).not_to be_valid
      expect(offer.errors[:amount_cents]).to be_present
    end

    it "rejects a negative amount" do
      offer = build(:offer, amount_cents: -100)

      expect(offer).not_to be_valid
    end

    it "accepts a positive amount" do
      offer = build(:offer, amount_cents: 1)

      expect(offer).to be_valid
    end
  end

  describe "accepted offer uniqueness" do
    it "allows only one accepted offer per listing" do
      listing = create(:listing, pricing_type: :negotiable)
      create(:offer, listing: listing, state: :accepted)
      duplicate = build(:offer, listing: listing, state: :accepted)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:listing_id]).to be_present
    end

    it "allows multiple pending offers on the same listing" do
      listing = create(:listing, pricing_type: :negotiable)
      create(:offer, listing: listing, state: :pending)
      second = build(:offer, listing: listing, state: :pending)

      expect(second).to be_valid
    end
  end

  describe "accepting an offer" do
    it "marks the listing as sold" do
      listing = create(:listing, pricing_type: :negotiable, state: :on_sale)
      offer   = create(:offer, listing: listing)

      offer.update!(state: :accepted)

      expect(listing.reload).to be_sold
    end
  end
end
