require "rails_helper"

RSpec.describe Listings::PropertySet, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "associations" do
    it "destroys associated properties when destroyed" do
      set = create(:listings_property_set)
      create(:listings_property, property_set: set)
      expect { set.destroy! }.to change(Listings::Property, :count).by(-1)
    end
  end
end
