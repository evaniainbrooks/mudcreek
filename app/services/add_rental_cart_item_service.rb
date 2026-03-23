class AddRentalCartItemService
  Result = Data.define(:cart_item, :error) do
    def success? = error.nil?
  end

  def self.call(listing:, user:, rental_start_at:, rental_end_at:)
    start_at = parse_time(rental_start_at)
    end_at   = parse_time(rental_end_at)

    unless start_at && end_at && end_at > start_at
      return Result.new(cart_item: nil, error: "Please select a valid date and time range.")
    end

    duration_minutes = ((end_at - start_at) / 60).ceil
    pricing = RentalPricingService.new(listing.rental_rate_plans).minimum_cost_for(duration_minutes)

    cart_item = user.cart_items.new(
      listing_id:         listing.id,
      rental_start_at:    start_at,
      rental_end_at:      end_at,
      rental_price_cents: pricing.total_cents
    )

    cart_item.build_rental_booking(
      listing:    listing,
      start_at:   start_at,
      end_at:     end_at,
      expires_at: 24.hours.from_now
    )

    if cart_item.save
      Result.new(cart_item:, error: nil)
    else
      booking_errors = cart_item.rental_booking&.errors&.full_messages.presence
      item_errors    = cart_item.errors.reject { |e| e.attribute.to_s == "rental_booking" }.map(&:full_message)
      Result.new(cart_item: nil, error: (booking_errors || item_errors).to_sentence)
    end
  end

  def self.parse_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
  private_class_method :parse_time
end
