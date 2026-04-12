require "rails_helper"

RSpec.describe Listings::VariantOptionValue, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:listing)      { create(:listing) }
  let(:option)       { Listings::Option.create!(listing: listing, name: "Size") }
  let(:option_value) { Listings::OptionValue.create!(option: option, value: "Medium") }
  let(:variant)      { Listings::Variant.create!(listing: listing, quantity: 5) }

  describe "validations" do
    it "enforces uniqueness of option_value per variant" do
      Listings::VariantOptionValue.create!(variant: variant, option_value: option_value)
      duplicate = Listings::VariantOptionValue.new(variant: variant, option_value: option_value)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:option_value_id]).to be_present
    end

    it "allows the same option_value on different variants" do
      other_variant = Listings::Variant.create!(listing: listing, quantity: 3)
      Listings::VariantOptionValue.create!(variant: variant, option_value: option_value)
      expect(
        Listings::VariantOptionValue.new(variant: other_variant, option_value: option_value)
      ).to be_valid
    end
  end
end
