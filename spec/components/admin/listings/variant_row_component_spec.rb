require "rails_helper"

RSpec.describe Admin::Listings::VariantRowComponent, type: :component do
  let(:tenant)  { Tenant.create!(name: "Test", key: "test", default: true) }
  let(:listing) { create(:listing) }
  let(:variant) { Listings::Variant.create!(listing: listing, quantity: 1) }

  let(:variant_form) do
    double("FormBuilder",
      object:       variant,
      hidden_field: nil,
      number_field: nil,
      text_field:   nil,
      check_box:    nil,
      label:        nil
    )
  end

  before { Current.tenant = tenant }

  describe "#gallery_representative?" do
    it "is true when gallery_representative_id is nil" do
      component = described_class.new(variant_form: variant_form, listing: listing, gallery_representative_id: nil)
      expect(component.gallery_representative?).to be true
    end

    it "is true when the variant is the representative" do
      component = described_class.new(variant_form: variant_form, listing: listing, gallery_representative_id: variant.id)
      expect(component.gallery_representative?).to be true
    end

    it "is false when another variant is the representative" do
      component = described_class.new(variant_form: variant_form, listing: listing, gallery_representative_id: variant.id + 1)
      expect(component.gallery_representative?).to be false
    end
  end

  describe "#photo_count" do
    it "returns 0 when the variant has no gallery" do
      component = described_class.new(variant_form: variant_form, listing: listing, gallery_representative_id: nil)
      expect(component.photo_count).to eq(0)
    end

    it "returns the number of attached photos" do
      allow(variant).to receive(:gallery).and_return(
        double("Gallery", photos: double("photos", size: 5))
      )
      component = described_class.new(variant_form: variant_form, listing: listing, gallery_representative_id: nil)
      expect(component.photo_count).to eq(5)
    end
  end

  describe "#gallery_representative_variant" do
    it "finds the variant whose id matches the representative id" do
      other = Listings::Variant.create!(listing: listing, quantity: 1)
      component = described_class.new(variant_form: variant_form, listing: listing, gallery_representative_id: other.id)
      expect(component.gallery_representative_variant).to eq(other)
    end
  end

  describe "gallery cell" do
    context "when the variant is the gallery representative with no photos" do
      subject(:component) do
        described_class.new(variant_form: variant_form, listing: listing, gallery_representative_id: variant.id)
      end

      it "renders a Gallery link" do
        render_inline component
        expect(page).to have_link("Gallery")
      end

      it "uses the outline button style" do
        render_inline component
        expect(page).to have_css("a.btn-outline-secondary", text: "Gallery")
      end
    end

    context "when the variant is the gallery representative with photos" do
      subject(:component) do
        described_class.new(variant_form: variant_form, listing: listing, gallery_representative_id: variant.id)
      end

      before do
        allow(variant).to receive(:gallery).and_return(
          double("Gallery", photos: double("photos", size: 3))
        )
      end

      it "shows the photo count as the link text" do
        render_inline component
        expect(page).to have_link("3")
      end

      it "uses the filled primary button style" do
        render_inline component
        expect(page).to have_css("a.btn-primary")
      end
    end

    context "when the variant is not the gallery representative" do
      let(:representative) { Listings::Variant.create!(listing: listing, quantity: 1) }

      subject(:component) do
        described_class.new(variant_form: variant_form, listing: listing, gallery_representative_id: representative.id)
      end

      it "renders a Shared link" do
        render_inline component
        expect(page).to have_link("Shared")
      end

      it "links to the representative variant's edit page" do
        render_inline component
        expect(page).to have_css("a[href*='/variants/#{representative.id}/edit']", text: "Shared")
      end

      it "does not render a Gallery link" do
        render_inline component
        expect(page).to have_no_link("Gallery")
      end
    end
  end
end
