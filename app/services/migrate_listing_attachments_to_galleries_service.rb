# Migrates Active Storage attachments that were previously attached directly to
# Listing records (names: images, videos, documents) to the listing's Gallery.
#
# Mapping:
#   Listing#images    → Gallery#photos
#   Listing#videos    → Gallery#videos
#   Listing#documents → Gallery#documents
#
# For each listing that has orphaned attachments, the service:
#   1. Finds or creates a Gallery (using the listing name if creating).
#   2. Reassigns each attachment record in-place — no files are copied or re-uploaded.
#
# Usage:
#   result = MigrateListingAttachmentsToGalleriesService.call
#   puts result.summary
#
# Safe to re-run: attachments already belonging to Gallery are left untouched.
# Iterates over every tenant automatically; does not require Current.tenant to
# be set by the caller.
class MigrateListingAttachmentsToGalleriesService
  ATTACHMENT_NAME_MAP = {
    "images"    => "photos",
    "videos"    => "videos",
    "documents" => "documents"
  }.freeze

  Result = Data.define(:listings_processed, :galleries_created, :attachments_migrated) do
    def summary
      "Processed #{listings_processed} listing(s): " \
        "created #{galleries_created} gallery/galleries, " \
        "migrated #{attachments_migrated} attachment(s)."
    end
  end

  def self.call = new.call

  def call
    listings_processed  = 0
    galleries_created   = 0
    attachments_migrated = 0

    # Query orphaned listing IDs once globally — active_storage_attachments has
    # no tenant_id, so a single cross-tenant query is correct here.
    orphaned_listing_ids = ActiveStorage::Attachment
      .where(record_type: "Listing", name: ATTACHMENT_NAME_MAP.keys)
      .distinct
      .pluck(:record_id)

    return Result.new(listings_processed: 0, galleries_created: 0, attachments_migrated: 0) if orphaned_listing_ids.empty?

    # Use unscoped to bypass the MultiTenant default_scope — we need listings
    # across all tenants in a single query, not filtered by Current.tenant.
    listings_by_tenant = Listing.unscoped
      .where(id: orphaned_listing_ids)
      .includes(:gallery, :tenant)
      .group_by(&:tenant_id)

    listings_by_tenant.each do |_tenant_id, listings|
      Current.tenant = listings.first.tenant

      listings.each do |listing|
        gallery, created = find_or_create_gallery(listing)
        galleries_created += 1 if created

        count = reassign_attachments(listing.id, gallery.id)
        attachments_migrated += count
        listings_processed   += 1

        Rails.logger.info(
          "[MigrateListingAttachments] tenant=#{Current.tenant.id} listing=#{listing.id} " \
          "gallery=#{gallery.id} created=#{created} attachments=#{count}"
        )
      end
    ensure
      Current.tenant = nil
    end

    Result.new(
      listings_processed:,
      galleries_created:,
      attachments_migrated:
    )
  end

  private

  def find_or_create_gallery(listing)
    if listing.gallery
      [ listing.gallery, false ]
    else
      gallery = listing.create_gallery!(name: listing.name)
      [ gallery, true ]
    end
  end

  def reassign_attachments(listing_id, gallery_id)
    total = 0

    ATTACHMENT_NAME_MAP.each do |old_name, new_name|
      count = ActiveStorage::Attachment
        .where(record_type: "Listing", record_id: listing_id, name: old_name)
        .update_all(record_type: "Gallery", record_id: gallery_id, name: new_name)

      total += count
    end

    total
  end
end
