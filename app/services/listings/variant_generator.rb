module Listings
  class VariantGenerator
    def self.call(listing:)
      option_values_by_option = listing.options.includes(:option_values).map { |o| o.option_values.to_a }
      return [] if option_values_by_option.empty?

      combinations = option_values_by_option.reduce([[]]) { |combos, vals| combos.product(vals).map(&:flatten) }
      existing = preload_existing_combos(listing)

      combinations.filter_map do |combo|
        next if existing.include?(combo.map(&:id).sort)

        variant = listing.variants.create!
        Listings::VariantOptionValue.insert_all!(
          combo.map { |ov| { variant_id: variant.id, option_value_id: ov.id } }
        )
        variant
      end
    end

    def self.preload_existing_combos(listing)
      Listings::VariantOptionValue
        .where(variant_id: listing.variants.select(:id))
        .pluck(:variant_id, :option_value_id)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last).sort }
        .values
        .to_set
    end
    private_class_method :preload_existing_combos
  end
end
