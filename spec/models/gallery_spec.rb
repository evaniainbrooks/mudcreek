require "rails_helper"

RSpec.describe Gallery, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "is valid with a name" do
      expect(build(:gallery)).to be_valid
    end

    it "requires a name" do
      gallery = build(:gallery, name: nil)
      expect(gallery).not_to be_valid
      expect(gallery.errors[:name]).to be_present
    end

    it "requires a tenant" do
      Current.tenant = nil
      gallery = Gallery.new(name: "Test")
      expect(gallery).not_to be_valid
      expect(gallery.errors[:tenant_id]).to be_present
    end
  end

  describe "multi-tenancy" do
    it "is scoped to the current tenant" do
      tenant_a = Current.tenant
      gallery_a = create(:gallery, name: "Tenant A Gallery")

      tenant_b = create(:tenant)
      Current.tenant = tenant_b
      gallery_b = create(:gallery, name: "Tenant B Gallery")

      Current.tenant = tenant_a
      expect(Gallery.all).to include(gallery_a)
      expect(Gallery.all).not_to include(gallery_b)
    ensure
      Current.tenant = tenant_a
    end
  end

  describe "name defaulting" do
    it "inherits the listing name when name is blank and a listing is present" do
      listing = create(:listing)
      gallery = listing.build_gallery
      gallery.valid?
      expect(gallery.name).to eq(listing.name)
    end

    it "does not override an explicitly set name" do
      listing = create(:listing)
      gallery = listing.build_gallery(name: "Custom Name")
      gallery.valid?
      expect(gallery.name).to eq("Custom Name")
    end

    it "does not set a name from listing when no listing is associated" do
      gallery = build(:gallery, name: nil)
      gallery.valid?
      expect(gallery.name).to be_nil
    end
  end

  describe "associations" do
    it "can belong to a listing" do
      listing = create(:listing)
      gallery = create(:gallery, listing: listing)
      expect(gallery.listing).to eq(listing)
    end

    it "does not require a listing" do
      expect(build(:gallery, listing: nil)).to be_valid
    end

    it "is destroyed when its listing is destroyed", :skip_n_plus_one do
      listing = create(:listing)
      gallery = create(:gallery, listing: listing)
      listing.destroy
      expect { gallery.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "is the one gallery for its listing" do
      listing = create(:listing)
      gallery = create(:gallery, listing: listing)
      expect(listing.gallery).to eq(gallery)
    end
  end

  describe "rich text" do
    it "has a description" do
      gallery = create(:gallery)
      gallery.description = "A wonderful collection of photos."
      gallery.save!
      expect(gallery.reload.description.to_plain_text).to eq("A wonderful collection of photos.")
    end
  end

  describe "attachments" do
    let(:gallery) { create(:gallery) }

    it "accepts attached photos" do
      gallery.photos.attach(
        io: StringIO.new("fake image data"),
        filename: "photo.jpg",
        content_type: "image/jpeg"
      )
      expect(gallery.photos).to be_attached
      expect(gallery.photos.count).to eq(1)
    end

    it "accepts multiple attached photos" do
      gallery.photos.attach(
        [
          { io: StringIO.new("fake image data 0"), filename: "photo_0.jpg", content_type: "image/jpeg" },
          { io: StringIO.new("fake image data 1"), filename: "photo_1.jpg", content_type: "image/jpeg" }
        ]
      )
      expect(gallery.photos.count).to eq(2)
    end

    it "accepts attached videos" do
      gallery.videos.attach(
        io: StringIO.new("fake video data"),
        filename: "video.mp4",
        content_type: "video/mp4"
      )
      expect(gallery.videos).to be_attached
      expect(gallery.videos.count).to eq(1)
    end

    it "accepts attached documents" do
      gallery.documents.attach(
        io: StringIO.new("fake pdf data"),
        filename: "document.pdf",
        content_type: "application/pdf"
      )
      expect(gallery.documents).to be_attached
      expect(gallery.documents.count).to eq(1)
    end

    it "tracks photos, videos, and documents independently" do
      gallery.photos.attach(io: StringIO.new("img"), filename: "a.jpg", content_type: "image/jpeg")
      gallery.videos.attach(io: StringIO.new("vid"), filename: "b.mp4", content_type: "video/mp4")
      gallery.documents.attach(io: StringIO.new("doc"), filename: "c.pdf", content_type: "application/pdf")

      expect(gallery.photos.count).to eq(1)
      expect(gallery.videos.count).to eq(1)
      expect(gallery.documents.count).to eq(1)
    end
  end
end
