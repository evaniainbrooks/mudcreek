class Listings::VariantGalleriesController < ApplicationController
  allow_unauthenticated_access

  def show
    @listing = Listing.where(published: true)
                      .includes(:options, gallery: { photos_attachments: :blob, videos_attachments: :blob })
                      .find_by!(hashid: params[:listing_hashid])
    @photos = resolve_photos
  end

  private

  def resolve_photos
    return listing_photos unless Current.tenant.features.listing_variants? && @listing.has_variants?

    ids = Array(params[:option_values]&.values).map(&:to_i).sort
    return listing_photos if ids.empty?

    gallery_option_ids = @listing.options.where(affects_gallery: true).ids

    variant = if gallery_option_ids.any?
      gallery_ids = Listings::OptionValue
        .where(option_id: gallery_option_ids, id: ids)
        .order(:id)
        .ids

      return listing_photos if gallery_ids.empty?

      @listing.variants
        .joins(
          "JOIN listings_variant_option_values vov ON vov.variant_id = listings_variants.id " \
          "JOIN listings_option_values lov ON lov.id = vov.option_value_id"
        )
        .where("lov.option_id IN (?)", gallery_option_ids)
        .group("listings_variants.id")
        .having("array_agg(lov.id ORDER BY lov.id) = ARRAY[?]::bigint[]", gallery_ids)
        .includes(gallery: { photos_attachments: :blob })
        .first
    else
      @listing.variants
        .joins(:option_values)
        .group("listings_variants.id")
        .having("array_agg(listings_option_values.id ORDER BY listings_option_values.id) = ARRAY[?]::bigint[]", ids)
        .includes(gallery: { photos_attachments: :blob })
        .first
    end

    photos = variant&.gallery&.photos
    photos&.attached? ? photos : listing_photos
  end

  def listing_photos = @listing.gallery&.photos || []
end
