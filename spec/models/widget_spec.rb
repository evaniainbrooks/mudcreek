require "rails_helper"

RSpec.describe Widget, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "STI subclasses" do
    it "GalleryWidget requires gallery_id" do
      widget = GalleryWidget.new(page: create(:page), position: 0)
      expect(widget).not_to be_valid
      expect(widget.errors[:gallery_id]).to be_present
    end

    it "LocationWidget requires location_id" do
      widget = LocationWidget.new(page: create(:page), position: 0)
      expect(widget).not_to be_valid
      expect(widget.errors[:location_id]).to be_present
    end

    it "ScheduleWidget requires location_id" do
      widget = ScheduleWidget.new(page: create(:page), position: 0)
      expect(widget).not_to be_valid
      expect(widget.errors[:location_id]).to be_present
    end

    it "ContactFormWidget requires inquiry_form_id" do
      widget = ContactFormWidget.new(page: create(:page), position: 0)
      expect(widget).not_to be_valid
      expect(widget.errors[:inquiry_form_id]).to be_present
    end

    it "QrCodeWidget requires qr_code_id" do
      widget = QrCodeWidget.new(page: create(:page), position: 0)
      expect(widget).not_to be_valid
      expect(widget.errors[:qr_code_id]).to be_present
    end

    it "ListingWidget requires listing_id" do
      widget = ListingWidget.new(page: create(:page), position: 0)
      expect(widget).not_to be_valid
      expect(widget.errors[:listing_id]).to be_present
    end
  end

  describe "multi-tenancy" do
    it "scopes to current tenant" do
      page = create(:page)
      gallery = create(:gallery)
      widget = GalleryWidget.create!(page: page, gallery: gallery, position: 0)
      expect(Widget.all).to include(widget)

      Current.tenant = create(:tenant)
      expect(Widget.all).not_to include(widget)
    end
  end

  describe "ordering" do
    it "orders by position by default" do
      page = create(:page)
      gallery = create(:gallery)
      w2 = GalleryWidget.create!(page: page, gallery: gallery, position: 2)
      w0 = GalleryWidget.create!(page: page, gallery: gallery, position: 0)
      w1 = GalleryWidget.create!(page: page, gallery: gallery, position: 1)
      expect(Widget.where(page: page).map(&:id)).to eq([ w0.id, w1.id, w2.id ])
    end
  end

  describe "cascade destroy" do
    it "is destroyed when page is destroyed", :skip_n_plus_one do
      page = create(:page)
      gallery = create(:gallery)
      widget = GalleryWidget.create!(page: page, gallery: gallery, position: 0)
      page.destroy!
      expect(Widget.where(id: widget.id)).to be_empty
    end
  end
end
