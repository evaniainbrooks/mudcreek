require "rails_helper"

RSpec.describe InvoiceItem, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "requires name" do
      item = build(:invoice_item, name: "")
      expect(item).not_to be_valid
      expect(item.errors[:name]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:invoice) }
    it { is_expected.to belong_to(:listing).optional }
  end
end
