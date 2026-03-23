class OrdersController < ApplicationController
  allow_unauthenticated_access only: %i[create show]

  def create
    if Current.user
      @cart_items = Current.user.cart_items.includes(:listing).order(:created_at)
    else
      token = session[:guest_cart_token]
      @cart_items = token ? CartItem.where(guest_cart_token: token).includes(:listing).order(:created_at) : CartItem.none
    end

    if @cart_items.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end

    reconcile_delivery_method

    if @cart_items.any? { |item| item.listing.requires_delivery? } && @delivery_method.nil?
      redirect_to cart_path, alert: "Please select a delivery method."
      return
    end

    addr = resolve_address
    if @delivery_method&.address_required?
      if addr[:street_address].blank? || addr[:city].blank? || addr[:postal_code].blank? || addr[:country].blank?
        redirect_to cart_path, alert: "Please provide a delivery address."
        return
      end
    end

    rental_items = @cart_items.select(&:rental?)
    rental_items.each do |item|
      booking = item.rental_booking
      if booking.nil? || booking.invalid?
        msg = booking&.errors&.full_messages&.first || "A rental item in your cart is no longer available."
        redirect_to cart_path, alert: msg
        return
      end
    end

    unless Current.user
      guest_email = session[:guest_email]
      guest_name  = session[:guest_name]
      if guest_email.blank? || guest_name.blank?
        redirect_to cart_path, alert: "Please provide your contact information."
        return
      end
    end

    reconcile_discount_code

    summary = CartCalculator.new(
      @cart_items, discount_code: @discount_code, delivery_method: @delivery_method
    ).calculate

    order = Order.new(
      user:                 Current.user,
      guest_email:          Current.user ? nil : session[:guest_email],
      guest_name:           Current.user ? nil : session[:guest_name],
      delivery_method:      @delivery_method,
      delivery_method_name: @delivery_method&.name,
      delivery_price_cents: summary.delivery_cents,
      discount_code:        @discount_code,
      discount_code_key:    @discount_code&.key,
      discount_cents:       summary.discount_cents,
      subtotal_cents:       summary.subtotal_cents,
      tax_cents:            summary.tax_cents,
      total_cents:          summary.total_cents,
      street_address:       addr[:street_address],
      city:                 addr[:city],
      province:             addr[:province],
      postal_code:          addr[:postal_code],
      country:              addr[:country]
    )

    @cart_items.each do |item|
      order.order_items.build(
        listing:         item.listing,
        name:            item.listing.name,
        variant_name:    item.variant&.display_name,
        price_cents:     item.effective_price.cents,
        listing_type:    item.listing.listing_type,
        rental_start_at: item.rental_start_at,
        rental_end_at:   item.rental_end_at
      )
    end

    ActiveRecord::Base.transaction do
      order.save!
    end

    # Extend rental booking expiry to past the rental end so they remain visible on calendars
    rental_items.each do |item|
      item.rental_booking&.update_columns(expires_at: item.rental_end_at + 1.day)
    end

    if Current.user
      Current.user.cart_items.destroy_all
    else
      CartItem.where(guest_cart_token: session.delete(:guest_cart_token)).destroy_all
      session.delete(:guest_email)
      session.delete(:guest_name)
      session.delete(:guest_address)
      session[:guest_order_token] = order.guest_token
    end
    session.delete(:delivery_method_id)
    session.delete(:discount_code_id)

    redirect_to order_path(order), notice: "Your order has been placed!"
  rescue ActiveRecord::RecordInvalid
    redirect_to cart_path, alert: "There was a problem placing your order. Please try again."
  end

  def show
    if Current.user
      @order = Current.user.orders.includes(:order_items).find_by!(number: params[:number])
    else
      token = params[:token] || session[:guest_order_token]
      raise ActiveRecord::RecordNotFound unless token.present?
      @order = Order.includes(:order_items).find_by!(number: params[:number], guest_token: token)
    end

    if @order.pending? && Current.user&.default_square_card_id.present?
      @saved_cards = SquareCustomerService.new(Current.user).list_cards
                       .select { |c| c.id == Current.user.default_square_card_id }
    end
    @saved_cards ||= []
  rescue SquareCustomerService::Error
    @saved_cards = []
  end

  private

  def resolve_address
    if Current.user
      cart_addr    = Current.user.cart_address
      profile_addr = Current.user.address
      {
        street_address: cart_addr&.street_address || profile_addr&.street_address,
        city:           cart_addr&.city           || profile_addr&.city,
        province:       cart_addr&.province       || profile_addr&.province,
        postal_code:    cart_addr&.postal_code    || profile_addr&.postal_code,
        country:        cart_addr&.country        || profile_addr&.country
      }
    else
      guest_addr = session[:guest_address] || {}
      {
        street_address: guest_addr[:street_address],
        city:           guest_addr[:city],
        province:       guest_addr[:province],
        postal_code:    guest_addr[:postal_code],
        country:        guest_addr[:country]
      }
    end
  end

  def reconcile_delivery_method
    return unless session[:delivery_method_id]

    method = DeliveryMethod.find_by(id: session[:delivery_method_id])

    if method.nil? || !method.active?
      session.delete(:delivery_method_id)
      @delivery_method = nil
    else
      @delivery_method = method
    end
  end

  def reconcile_discount_code
    return unless session[:discount_code_id]

    code = DiscountCode.find_by(id: session[:discount_code_id])

    if code.nil? || !code.active?
      session.delete(:discount_code_id)
      @discount_code = nil
    else
      @discount_code = code
    end
  end
end
