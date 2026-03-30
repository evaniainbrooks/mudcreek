require "rails_helper"

RSpec.describe Listings::VariantGenerator, skip_n_plus_one: true do
  before { Current.tenant = create(:tenant) }

  let(:listing) { create(:listing) }

  def make_option(name, *values)
    option = listing.options.create!(name: name)
    values.map { |v| option.option_values.create!(value: v) }
  end

  describe ".call" do
    context "when the listing has no options" do
      it "returns an empty array" do
        expect(described_class.call(listing: listing)).to eq([])
      end

      it "creates no variants" do
        expect { described_class.call(listing: listing) }.not_to change { listing.variants.count }
      end
    end

    context "when the listing has a single option with multiple values" do
      before { make_option("Size", "Small", "Medium", "Large") }

      it "creates one variant per value" do
        expect { described_class.call(listing: listing) }.to change { listing.variants.count }.by(3)
      end

      it "returns the created variants" do
        result = described_class.call(listing: listing)
        expect(result.size).to eq(3)
        expect(result).to all(be_a(Listings::Variant))
      end
    end

    context "when the listing has two options" do
      before do
        make_option("Size", "Small", "Medium", "Large")
        make_option("Color", "Red", "Green", "Blue")
      end

      it "creates the full Cartesian product (9 variants)" do
        expect { described_class.call(listing: listing) }.to change { listing.variants.count }.by(9)
      end

      it "returns all 9 created variants" do
        result = described_class.call(listing: listing)
        expect(result.size).to eq(9)
      end

      it "assigns exactly two option values to each variant" do
        described_class.call(listing: listing)
        listing.variants.each do |variant|
          expect(variant.option_values.count).to eq(2)
        end
      end

      it "produces every combination of values" do
        described_class.call(listing: listing)
        combinations = listing.variants.map { |v| v.option_values.map(&:value).sort }
        expect(combinations).to match_array([
          %w[Red Small].sort,   %w[Green Small].sort,  %w[Blue Small].sort,
          %w[Red Medium].sort,  %w[Green Medium].sort, %w[Blue Medium].sort,
          %w[Red Large].sort,   %w[Green Large].sort,  %w[Blue Large].sort
        ])
      end
    end

    context "when some variants already exist" do
      let!(:size_values)  { make_option("Size", "Small", "Medium", "Large") }
      let!(:color_values) { make_option("Color", "Red", "Green", "Blue") }

      before do
        # Pre-create Red/Small
        variant = listing.variants.create!
        variant.variant_option_values.create!(option_value: color_values.find { |v| v.value == "Red" })
        variant.variant_option_values.create!(option_value: size_values.find { |v| v.value == "Small" })
      end

      it "skips the exact existing combination" do
        expect { described_class.call(listing: listing) }.to change { listing.variants.count }.by(8)
      end

      it "does not skip combinations that merely share an option value with an existing variant" do
        described_class.call(listing: listing)
        combinations = listing.variants.map { |v| v.option_values.map(&:value).sort }
        # Red/Medium and Red/Large should exist even though Red/Small is pre-existing
        expect(combinations).to include(%w[Red Medium].sort, %w[Red Large].sort)
      end

      it "returns only the newly created variants" do
        result = described_class.call(listing: listing)
        expect(result.size).to eq(8)
      end
    end

    context "when called twice with the same options" do
      before do
        make_option("Size", "Small", "Medium")
        make_option("Color", "Red", "Green")
      end

      it "is idempotent — creates no duplicates on the second call" do
        described_class.call(listing: listing)
        expect { described_class.call(listing: listing) }.not_to change { listing.variants.count }
      end
    end
  end
end
