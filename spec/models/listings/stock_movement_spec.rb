require "rails_helper"

RSpec.describe Listings::StockMovement, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:listing) { create(:listing) }

  def build_movement(attrs = {})
    Listings::StockMovement.new(
      { listing: listing, kind: :stock_in, reason: :acquisition,
        quantity: 5, transacted_on: Date.current }.merge(attrs)
    )
  end

  describe "validations" do
    it "requires quantity" do
      expect(build_movement(quantity: nil)).not_to be_valid
    end

    it "rejects quantity of zero" do
      movement = build_movement(quantity: 0)
      expect(movement).not_to be_valid
      expect(movement.errors[:quantity]).to be_present
    end

    it "rejects a negative quantity" do
      expect(build_movement(quantity: -1)).not_to be_valid
    end

    it "requires transacted_on" do
      movement = build_movement(transacted_on: nil)
      expect(movement).not_to be_valid
      expect(movement.errors[:transacted_on]).to be_present
    end

    it "enforces uniqueness of order_item_id" do
      order_item = create(:order_item)
      Listings::StockMovement.create!(listing: listing, kind: :stock_out, reason: :online_order,
                                      quantity: 1, transacted_on: Date.current, order_item: order_item)
      duplicate = build_movement(kind: :stock_out, reason: :online_order, order_item: order_item)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:order_item_id]).to be_present
    end
  end
end
