require "rails_helper"

RSpec.describe Listings::Delivery, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:delivery_method_set) { create(:listings_delivery_method_set) }
  let(:delivery_method)     { create(:delivery_method) }

  describe "associations" do
    it "belongs to a delivery_method_set" do
      delivery = Listings::Delivery.create!(delivery_method_set: delivery_method_set, delivery_method: delivery_method)
      expect(delivery.delivery_method_set).to eq(delivery_method_set)
    end

    it "belongs to a delivery_method" do
      delivery = Listings::Delivery.create!(delivery_method_set: delivery_method_set, delivery_method: delivery_method)
      expect(delivery.delivery_method).to eq(delivery_method)
    end
  end
end
