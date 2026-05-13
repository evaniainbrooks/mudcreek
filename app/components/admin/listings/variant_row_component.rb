class Admin::Listings::VariantRowComponent < ViewComponent::Base
  def initialize(variant_form:, listing:, gallery_representative_id:)
    @variant_form = variant_form
    @listing = listing
    @gallery_representative_id = gallery_representative_id
    @variant = variant_form.object
  end

  def gallery_representative?
    @gallery_representative_id.nil? || @variant.id == @gallery_representative_id
  end

  def photo_count
    @variant.gallery&.photos&.size || 0
  end

  def gallery_representative_variant
    @listing.variants.find { |v| v.id == @gallery_representative_id }
  end
end
