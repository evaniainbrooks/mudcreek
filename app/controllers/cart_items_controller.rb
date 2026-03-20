class CartItemsController < ApplicationController
  allow_unauthenticated_access

  def create
    @listing = Listing.find(params[:listing_id])

    if @listing.rental?
      if Current.user
        create_rental_cart_item
      else
        redirect_to new_session_path, alert: "Please sign in to book rentals."
      end
    else
      quantity = params[:quantity].to_i.clamp(1, @listing.quantity)
      cart_items_scope.create(listing_id: @listing.id, quantity:)

      respond_to do |format|
        format.turbo_stream do
          @offcanvas_cart_items = load_offcanvas_cart_items
          @new_cart_item = cart_items_scope.find_by(listing_id: @listing.id)
        end
        format.html do
          redirect_back fallback_location: root_path,
            notice: helpers.safe_join([ "Added to cart. ", helpers.link_to("View cart", cart_path) ])
        end
      end
    end
  end

  def update
    cart_item = find_cart_item(params[:id])
    quantity = params[:quantity].to_i.clamp(1, cart_item.listing.quantity)
    cart_item.update(quantity:)
    redirect_back fallback_location: cart_path, notice: "Quantity updated."
  end

  def destroy
    cart_item = find_cart_item(params[:id])
    cart_item.destroy
    redirect_back fallback_location: cart_path, notice: "Removed from cart."
  end

  private

  def load_offcanvas_cart_items
    scope = if Current.user
      Current.user.cart_items
    else
      token = session[:guest_cart_token]
      token ? CartItem.where(guest_cart_token: token) : CartItem.none
    end
    scope.includes(listing: { images_attachments: :blob }).order(:created_at)
  end

  def cart_items_scope
    if Current.user
      Current.user.cart_items
    else
      token = session[:guest_cart_token] ||= SecureRandom.uuid
      CartItem.where(guest_cart_token: token)
    end
  end

  def find_cart_item(id)
    if Current.user
      Current.user.cart_items.find(id)
    else
      token = session[:guest_cart_token]
      raise ActiveRecord::RecordNotFound unless token
      CartItem.find_by!(id:, guest_cart_token: token)
    end
  end

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
      errors = booking.errors.full_messages.presence ||
               cart_item.errors.reject { |e| e.attribute.to_s == "rental_booking" }.map(&:full_message)
      redirect_back fallback_location: listing_path(@listing),
        alert: errors.to_sentence
    end
  end
end
