module Listings
  class VariantGenerator
    def self.call(listing:)
      option_values_by_option = listing.options.includes(:option_values).map { |o| o.option_values.to_a }
      return [] if option_values_by_option.empty?

      combinations = option_values_by_option.reduce([[]]) { |combos, vals| combos.product(vals).map(&:flatten) }

      combinations.each_with_object([]) do |combo, created|
        next if exists?(listing, combo)
        variant = listing.variants.create!
        combo.each { |ov| variant.variant_option_values.create!(option_value: ov) }
        created << variant
      end
    end

    def self.exists?(listing, combo)
      combo.reduce(listing.variants) { |q, ov|
        q.where("EXISTS (SELECT 1 FROM listings_variant_option_values WHERE variant_id = listings_variants.id AND option_value_id = ?)", ov.id)
      }.where("(SELECT COUNT(*) FROM listings_variant_option_values WHERE variant_id = listings_variants.id) = ?", combo.size).exists?
    end
    private_class_method :exists?
  end
end
