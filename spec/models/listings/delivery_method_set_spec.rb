require "rails_helper"

RSpec.describe Listings::DeliveryMethodSet, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "associations" do
    let(:set)    { create(:listings_delivery_method_set) }
    let(:method) { create(:delivery_method) }

    it "has many delivery_methods through deliveries" do
      Listings::Delivery.create!(delivery_method_set: set, delivery_method: method)
      expect(set.delivery_methods).to include(method)
    end

    it "destroys associated deliveries when destroyed" do
      Listings::Delivery.create!(delivery_method_set: set, delivery_method: method)
      expect { set.destroy! }.to change(Listings::Delivery, :count).by(-1)
    end
  end
end
