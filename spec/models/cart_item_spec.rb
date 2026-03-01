require "rails_helper"

RSpec.describe CartItem, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:user)    { create(:user) }
  let(:listing) { create(:listing) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:listing) }
    it { is_expected.to have_one(:rental_booking).dependent(:destroy) }
  end

  describe "validations" do
    it "prevents the same user from adding the same listing twice" do
      create(:cart_item, user: user, listing: listing)
      duplicate = build(:cart_item, user: user, listing: listing)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:listing_id]).to be_present
    end

    it "allows different users to add the same listing" do
      other_user = create(:user)
      create(:cart_item, user: user, listing: listing)
      second = build(:cart_item, user: other_user, listing: listing)

      expect(second).to be_valid
    end

    it "allows the same user to add different listings" do
      other_listing = create(:listing)
      create(:cart_item, user: user, listing: listing)
      second = build(:cart_item, user: user, listing: other_listing)

      expect(second).to be_valid
    end
  end

  describe "#rental?" do
    it "returns false when rental_start_at is nil" do
      item = build(:cart_item)

      expect(item.rental?).to be false
    end

    it "returns true when rental_start_at is present" do
      item = build(:cart_item, :rental)

      expect(item.rental?).to be true
    end
  end

  describe "#effective_price_cents" do
    it "returns the listing price for a sale item" do
      item = build(:cart_item, listing: listing)

      expect(item.effective_price_cents).to eq(listing.price_cents)
    end

    it "returns rental_price_cents for a rental item" do
      item = build(:cart_item, :rental, listing: listing, rental_price_cents: 4000)

      expect(item.effective_price_cents).to eq(4000)
    end
  end
end
