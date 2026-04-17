require "rails_helper"

RSpec.describe MigrateListingAttachmentsToGalleriesService do
  # The service iterates over all tenants itself; we only need Current.tenant
  # set during the setup phase so that FactoryBot creates records correctly.
  let(:tenant) { create(:tenant) }

  def with_tenant(t = tenant)
    Current.tenant = t
    yield
  ensure
    Current.tenant = nil
  end

  def attach_to_listing(listing, name, filename: "file.jpg", content_type: "image/jpeg")
    listing.public_send(name).attach(
      io:           StringIO.new("fake data"),
      filename:     filename,
      content_type: content_type
    )
  end

  # Temporarily expose legacy attachment names on Listing so we can seed test
  # data without modifying the real model.
  def with_legacy_listing_attachments
    Listing.class_eval do
      has_many_attached :images
      has_many_attached :videos
      has_many_attached :documents
    end
    yield
  ensure
    Listing.attachment_reflections.delete("images")
    Listing.attachment_reflections.delete("videos")
    Listing.attachment_reflections.delete("documents")
  end

  describe ".call" do
    context "when a listing has images attached but no gallery" do
      it "creates a gallery for the listing" do
        listing = with_tenant { create(:listing, name: "Vintage Chair") }
        with_legacy_listing_attachments { with_tenant { attach_to_listing(listing, :images) } }

        expect { described_class.call }.to change(Gallery, :count).by(1)
      end

      it "names the gallery after the listing" do
        listing = with_tenant { create(:listing, name: "Vintage Chair") }
        with_legacy_listing_attachments { with_tenant { attach_to_listing(listing, :images) } }

        described_class.call

        expect(listing.reload.gallery.name).to eq("Vintage Chair")
      end

      it "migrates images to gallery photos" do
        listing = with_tenant { create(:listing) }
        with_legacy_listing_attachments { with_tenant { attach_to_listing(listing, :images, filename: "chair.jpg") } }

        described_class.call

        expect(listing.reload.gallery.photos.map(&:filename).map(&:to_s)).to include("chair.jpg")
      end

      it "removes the attachment from the listing" do
        listing = with_tenant { create(:listing) }
        with_legacy_listing_attachments { with_tenant { attach_to_listing(listing, :images) } }

        described_class.call

        count = ActiveStorage::Attachment.where(record_type: "Listing", record_id: listing.id, name: "images").count
        expect(count).to eq(0)
      end
    end

    context "when a listing has videos attached" do
      it "migrates videos to the gallery under the videos name" do
        listing = with_tenant { create(:listing) }
        with_legacy_listing_attachments do
          with_tenant { attach_to_listing(listing, :videos, filename: "tour.mp4", content_type: "video/mp4") }
        end

        described_class.call

        expect(listing.reload.gallery.videos.map(&:filename).map(&:to_s)).to include("tour.mp4")
      end
    end

    context "when a listing has documents attached" do
      it "migrates documents to the gallery under the documents name" do
        listing = with_tenant { create(:listing) }
        with_legacy_listing_attachments do
          with_tenant { attach_to_listing(listing, :documents, filename: "spec.pdf", content_type: "application/pdf") }
        end

        described_class.call

        expect(listing.reload.gallery.documents.map(&:filename).map(&:to_s)).to include("spec.pdf")
      end
    end

    context "when a listing has multiple attachment types" do
      it "migrates all of them and reports the correct count" do
        listing = with_tenant { create(:listing) }
        with_legacy_listing_attachments do
          with_tenant do
            attach_to_listing(listing, :images, filename: "a.jpg")
            attach_to_listing(listing, :images, filename: "b.jpg")
            attach_to_listing(listing, :videos, filename: "v.mp4", content_type: "video/mp4")
          end
        end

        result = described_class.call

        expect(result.attachments_migrated).to eq(3)
        expect(listing.reload.gallery.photos.count).to eq(2)
        expect(listing.reload.gallery.videos.count).to eq(1)
      end
    end

    context "when the listing already has a gallery" do
      it "uses the existing gallery instead of creating a new one" do
        listing          = with_tenant { create(:listing) }
        existing_gallery = with_tenant { create(:gallery, listing: listing, name: "Existing") }
        with_legacy_listing_attachments { with_tenant { attach_to_listing(listing, :images, filename: "new.jpg") } }

        expect { described_class.call }.not_to change(Gallery, :count)

        expect(existing_gallery.reload.photos.map(&:filename).map(&:to_s)).to include("new.jpg")
      end
    end

    context "when multiple listings have orphaned attachments" do
      # Creating multiple listings triggers per-record hashid uniqueness checks
      # and position MAX queries — inherent to the model, not the service under test.
      it "processes each listing independently", :skip_n_plus_one do
        listing_a, listing_b = with_tenant { [ create(:listing), create(:listing) ] }
        with_legacy_listing_attachments do
          with_tenant do
            attach_to_listing(listing_a, :images, filename: "a.jpg")
            attach_to_listing(listing_b, :images, filename: "b.jpg")
          end
        end

        result = described_class.call

        expect(result.listings_processed).to eq(2)
        expect(result.galleries_created).to eq(2)
        expect(listing_a.reload.gallery.photos.map(&:filename).map(&:to_s)).to include("a.jpg")
        expect(listing_b.reload.gallery.photos.map(&:filename).map(&:to_s)).to include("b.jpg")
      end
    end

    context "with multiple tenants" do
      it "migrates each tenant's listings independently", :skip_n_plus_one do
        other_tenant = create(:tenant)

        listing_a = with_tenant(tenant)       { create(:listing) }
        listing_b = with_tenant(other_tenant) { create(:listing) }

        with_legacy_listing_attachments do
          with_tenant(tenant)       { attach_to_listing(listing_a, :images, filename: "tenant_a.jpg") }
          with_tenant(other_tenant) { attach_to_listing(listing_b, :images, filename: "tenant_b.jpg") }
        end

        result = described_class.call

        expect(result.listings_processed).to eq(2)
        expect(listing_a.reload.gallery.photos.map(&:filename).map(&:to_s)).to include("tenant_a.jpg")
        expect(listing_b.reload.gallery.photos.map(&:filename).map(&:to_s)).to include("tenant_b.jpg")
      end

      it "does not create galleries across tenant boundaries", :skip_n_plus_one do
        other_tenant = create(:tenant)
        listing_a    = with_tenant(tenant) { create(:listing) }

        with_legacy_listing_attachments do
          with_tenant(tenant) { attach_to_listing(listing_a, :images) }
        end

        described_class.call

        with_tenant(other_tenant) do
          expect(Gallery.count).to eq(0)
        end
      end
    end

    context "when there are no orphaned attachments" do
      before { tenant } # ensure at least one tenant exists

      it "returns zero counts" do
        result = described_class.call

        expect(result.listings_processed).to eq(0)
        expect(result.galleries_created).to eq(0)
        expect(result.attachments_migrated).to eq(0)
      end

      it "does not create any galleries" do
        expect { described_class.call }.not_to change(Gallery, :count)
      end
    end

    context "when run a second time (idempotency)" do
      it "does not double-migrate already-moved attachments" do
        listing = with_tenant { create(:listing) }
        with_legacy_listing_attachments { with_tenant { attach_to_listing(listing, :images, filename: "once.jpg") } }

        described_class.call
        result = described_class.call

        expect(result.listings_processed).to eq(0)
        expect(result.attachments_migrated).to eq(0)
      end
    end

    it "returns a result with a human-readable summary" do
      listing = with_tenant { create(:listing, name: "Oak Table") }
      with_legacy_listing_attachments { with_tenant { attach_to_listing(listing, :images) } }

      result = described_class.call

      expect(result.summary).to include("1 listing")
      expect(result.summary).to include("1 gallery")
      expect(result.summary).to include("1 attachment")
    end
  end
end
