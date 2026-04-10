require "rails_helper"

RSpec.describe Listings::Variant, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:listing) { create(:listing) }

  def build_variant(attrs = {})
    Listings::Variant.new({ listing: listing, quantity: 10 }.merge(attrs))
  end

  describe "validations" do
    it "rejects a negative quantity" do
      variant = build_variant(quantity: -1)
      expect(variant).not_to be_valid
      expect(variant.errors[:quantity]).to be_present
    end

    it "accepts quantity of zero" do
      expect(build_variant(quantity: 0)).to be_valid
    end
  end

  describe "#effective_price_cents" do
    it "returns the variant price when set" do
      variant = build_variant(price_cents: 2000)
      expect(variant.effective_price_cents).to eq(2000)
    end

    it "falls back to the listing price when no variant price is set" do
      listing.price_cents = 1500
      variant = build_variant(price_cents: nil)
      expect(variant.effective_price_cents).to eq(1500)
    end
  end
end
