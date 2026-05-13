class Admin::Listings::VariantsSectionComponent < ViewComponent::Base
  def initialize(form:, listing:)
    @form = form
    @listing = listing
  end

  def gallery_representative_id_for(variant)
    return nil if gallery_representatives.nil?

    gallery_representatives[variant_gallery_key(variant.id)]
  end

  private

  def gallery_option_ids
    @gallery_option_ids ||= @listing.options.select(&:affects_gallery).map(&:id).to_set
  end

  # Single query: variant_id → sorted gallery-affecting option_value_ids
  def variant_gallery_keys
    @variant_gallery_keys ||= Listings::VariantOptionValue
      .joins(:option_value)
      .where(variant_id: @listing.variants.map(&:id))
      .where(listings_option_values: { option_id: gallery_option_ids.to_a })
      .pluck(:variant_id, :option_value_id)
      .group_by(&:first)
      .transform_values { |pairs| pairs.map(&:last).sort }
  end

  def variant_gallery_key(variant_id)
    variant_gallery_keys.fetch(variant_id, [])
  end

  def gallery_representatives
    return @gallery_representatives if defined?(@gallery_representatives)
    return @gallery_representatives = nil unless gallery_option_ids.any?

    @gallery_representatives = @listing.variants.each_with_object({}) do |v, hash|
      key = variant_gallery_key(v.id)
      hash[key] ||= v.id
    end
  end
end
