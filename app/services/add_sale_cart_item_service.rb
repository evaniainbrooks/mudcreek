class AddSaleCartItemService
  Result = Data.define(:cart_item, :error) do
    def success? = error.nil?
  end

  # option_value_ids: Array of OptionValue IDs selected by the buyer (when variants are in play)
  # variants_enabled: whether the listing_variants feature is on for this tenant
  def self.call(listing:, cart_items_scope:, requested_quantity: 1, option_value_ids: [], variants_enabled: false)
    variant = nil

    if variants_enabled && listing.has_variants?
      ids = option_value_ids.map(&:to_i).sort
      return Result.new(cart_item: nil, error: "Please select all options.") if ids.empty?

      variant = listing.variants
        .joins(:option_values)
        .group("listings_variants.id")
        .having(
          "array_agg(listings_option_values.id ORDER BY listings_option_values.id) = ARRAY[?]::bigint[]",
          ids
        )
        .first

      return Result.new(cart_item: nil, error: "The selected combination is not available.") unless variant
    end

    quantity = if listing.unlimited_quantity?
      1
    else
      max_qty = variant ? variant.quantity : listing.quantity
      requested_quantity.to_i.clamp(1, [max_qty, 1].max)
    end

    cart_item = cart_items_scope.create(listing_id: listing.id, variant:, quantity:)
    Result.new(cart_item:, error: nil)
  end
end
