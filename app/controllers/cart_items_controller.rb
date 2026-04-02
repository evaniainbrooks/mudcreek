class CartItemsController < ApplicationController
  allow_unauthenticated_access

  def create
    @listing = Listing.find(params[:listing_id])

    if @listing.rental?
      unless Current.user
        redirect_to new_session_path, alert: "Please sign in to book rentals."
        return
      end
      create_rental
    else
      create_sale
    end
  end

  def update
    cart_item = find_cart_item(params[:id])
    quantity = cart_item.listing.unlimited_quantity? ? 1 : params[:quantity].to_i.clamp(1, cart_item.listing.quantity)
    cart_item.update(quantity:)
    redirect_back fallback_location: cart_path, notice: "Quantity updated."
  end

  def destroy
    cart_item = find_cart_item(params[:id])
    cart_item.destroy
    redirect_back fallback_location: cart_path, notice: "Removed from cart."
  end

  private

  def create_sale
    result = AddSaleCartItemService.call(
      listing:            @listing,
      cart_items_scope:   cart_items_scope,
      requested_quantity: params[:quantity],
      option_value_ids:   Array(params[:option_values]&.values),
      variants_enabled:   Current.tenant.features.listing_variants?
    )

    unless result.success?
      redirect_back fallback_location: listing_path(@listing), alert: result.error
      return
    end

    respond_to do |format|
      format.turbo_stream do
        @offcanvas_cart_items = load_offcanvas_cart_items
        @new_cart_item = result.cart_item
      end
      format.html do
        redirect_back fallback_location: root_path,
          notice: helpers.safe_join(["Added to cart. ", helpers.link_to("View cart", cart_path)])
      end
    end
  end

  def create_rental
    result = AddRentalCartItemService.call(
      listing:          @listing,
      user:             Current.user,
      rental_start_at:  params[:rental_start_at],
      rental_end_at:    params[:rental_end_at]
    )

    if result.success?
      redirect_back fallback_location: root_path,
        notice: helpers.safe_join(["Rental added to cart. ", helpers.link_to("View cart", cart_path)])
    else
      redirect_back fallback_location: listing_path(@listing), alert: result.error
    end
  end

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
end
