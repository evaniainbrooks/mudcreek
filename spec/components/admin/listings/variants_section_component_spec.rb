require "rails_helper"

RSpec.describe Admin::Listings::VariantsSectionComponent, type: :component do
  let(:tenant) { Tenant.create!(name: "Test", key: "test", default: true) }
  let(:listing) { create(:listing) }
  let(:form_double) { double("FormBuilder", fields_for: nil) }

  before { Current.tenant = tenant }

  def make_option(listing:, name:, affects_gallery: false)
    Listings::Option.create!(listing: listing, name: name, affects_gallery: affects_gallery)
  end

  def make_option_value(option:, value:)
    Listings::OptionValue.create!(option: option, value: value)
  end

  def make_variant(listing:, option_values: [])
    Listings::Variant.create!(listing: listing, quantity: 1).tap do |v|
      option_values.each { |ov| Listings::VariantOptionValue.create!(variant: v, option_value: ov) }
    end
  end

  describe "#gallery_representative_id_for" do
    context "when no options affect the gallery" do
      it "returns nil for any variant" do
        opt     = make_option(listing: listing, name: "Color", affects_gallery: false)
        val     = make_option_value(option: opt, value: "Red")
        variant = make_variant(listing: listing, option_values: [val])

        component = described_class.new(form: form_double, listing: listing.reload)
        expect(component.gallery_representative_id_for(variant)).to be_nil
      end
    end

    context "when Color affects the gallery but Size does not" do
      let(:color)  { make_option(listing: listing, name: "Color", affects_gallery: true) }
      let(:size)   { make_option(listing: listing, name: "Size",  affects_gallery: false) }
      let(:red)    { make_option_value(option: color, value: "Red") }
      let(:blue)   { make_option_value(option: color, value: "Blue") }
      let(:small)  { make_option_value(option: size, value: "Small") }
      let(:medium) { make_option_value(option: size, value: "Medium") }

      let!(:red_small)  { make_variant(listing: listing, option_values: [red, small]) }
      let!(:red_medium) { make_variant(listing: listing, option_values: [red, medium]) }
      let!(:blue_small) { make_variant(listing: listing, option_values: [blue, small]) }

      let(:component) { described_class.new(form: form_double, listing: listing.reload) }

      it "assigns the same representative to Red/Small and Red/Medium" do
        expect(component.gallery_representative_id_for(red_small))
          .to eq(component.gallery_representative_id_for(red_medium))
      end

      it "uses the first Red variant as the Red gallery representative" do
        expect(component.gallery_representative_id_for(red_small)).to eq(red_small.id)
        expect(component.gallery_representative_id_for(red_medium)).to eq(red_small.id)
      end

      it "treats Blue variants as their own gallery group" do
        expect(component.gallery_representative_id_for(blue_small)).to eq(blue_small.id)
      end

      it "assigns different representatives to Red and Blue groups" do
        expect(component.gallery_representative_id_for(red_small))
          .not_to eq(component.gallery_representative_id_for(blue_small))
      end
    end
  end

  describe "rendering" do
    context "when the listing has not been saved yet" do
      let(:unsaved_listing) { Listing.new }

      it "shows the save-first message" do
        render_inline described_class.new(form: form_double, listing: unsaved_listing)
        expect(page).to have_text("Save the listing first")
      end

      it "does not show the generate button" do
        render_inline described_class.new(form: form_double, listing: unsaved_listing)
        expect(page).to have_no_link("Generate from Options")
      end
    end

    context "when the listing is persisted with no variants" do
      it "shows the no-variants message" do
        render_inline described_class.new(form: form_double, listing: listing)
        expect(page).to have_text("No variants yet")
      end

      it "shows a link to generate variants from options" do
        render_inline described_class.new(form: form_double, listing: listing)
        expect(page).to have_link("Generate from Options")
      end
    end

    context "when the listing has variants" do
      before do
        opt = make_option(listing: listing, name: "Color")
        val = make_option_value(option: opt, value: "Red")
        make_variant(listing: listing, option_values: [val])
      end

      it "renders the variants table" do
        render_inline described_class.new(form: form_double, listing: listing.reload)
        expect(page).to have_css("table")
      end

      it "includes the expected column headers" do
        render_inline described_class.new(form: form_double, listing: listing.reload)
        %w[Combination Qty SKU Gallery].each do |header|
          expect(page).to have_css("th", text: header)
        end
      end
    end
  end
end
