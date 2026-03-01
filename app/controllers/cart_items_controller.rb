class CartItemsController < ApplicationController
  def create
    @listing = Listing.find(params[:listing_id])

    if @listing.rental?
      create_rental_cart_item
    else
      Current.user.cart_items.create(listing_id: @listing.id)
      redirect_back fallback_location: root_path,
        notice: helpers.safe_join([ "Added to cart. ", helpers.link_to("View cart", cart_path) ])
    end
  end

  def destroy
    cart_item = Current.user.cart_items.find(params[:id])
    cart_item.destroy
    redirect_back fallback_location: cart_path, notice: "Removed from cart."
  end

  private

  def create_rental_cart_item
    start_at = (Time.zone.parse(params[:rental_start_at]) rescue nil)
    end_at   = (Time.zone.parse(params[:rental_end_at])   rescue nil)

    unless start_at && end_at && end_at > start_at
      redirect_back fallback_location: listing_path(@listing),
        alert: "Please select a valid date and time range."
      return
    end

    duration_minutes = ((end_at - start_at) / 60).ceil
    result = RentalPricingService.new(@listing.rental_rate_plans).minimum_cost_for(duration_minutes)

    cart_item = Current.user.cart_items.new(
      listing_id:         @listing.id,
      rental_start_at:    start_at,
      rental_end_at:      end_at,
      rental_price_cents: result.total_cents
    )

    booking = cart_item.build_rental_booking(
      listing:    @listing,
      start_at:   start_at,
      end_at:     end_at,
      expires_at: 24.hours.from_now
    )

    if cart_item.save
      redirect_back fallback_location: root_path,
        notice: helpers.safe_join([ "Rental added to cart. ", helpers.link_to("View cart", cart_path) ])
    else
      errors = (cart_item.errors.full_messages + booking.errors.full_messages).uniq
      redirect_back fallback_location: listing_path(@listing),
        alert: errors.to_sentence
    end
  end
end
