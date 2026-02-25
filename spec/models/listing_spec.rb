require 'rails_helper'

RSpec.describe Listing, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:owner).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:price_cents) }
  end

  describe "monetization" do
    it "exposes price as a Money object" do
      listing = build(:listing, price_cents: 1999)
      expect(listing.price).to eq(Money.new(1999, "USD"))
    end
  end

  describe "db constraints" do
    it "rejects a negative price_cents" do
      listing = build(:listing, price_cents: -1)
      expect { listing.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
