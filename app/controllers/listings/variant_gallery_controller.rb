class Listings::VariantGalleryController < ApplicationController
  allow_unauthenticated_access

  def show
    @listing = Listing.where(published: true)
                      .includes(gallery: { photos_attachments: :blob, videos_attachments: :blob })
                      .find_by!(hashid: params[:listing_hashid])
    @photos = resolve_photos
  end

  private

  def resolve_photos
    return listing_photos unless Current.tenant.features.listing_variants? && @listing.has_variants?

    ids = Array(params[:option_values]&.values).map(&:to_i).sort
    return listing_photos if ids.empty?

    variant = @listing.variants
      .joins(:option_values)
      .group("listings_variants.id")
      .having("array_agg(listings_option_values.id ORDER BY listings_option_values.id) = ARRAY[?]::bigint[]", ids)
      .includes(gallery: { photos_attachments: :blob })
      .first

    photos = variant&.gallery&.photos
    photos&.attached? ? photos : listing_photos
  end

  def listing_photos = @listing.gallery&.photos || []
end
