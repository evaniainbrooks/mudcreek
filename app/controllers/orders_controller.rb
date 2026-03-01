class OrdersController < ApplicationController
  def create
    @cart_items = Current.user.cart_items.includes(:listing).order(:created_at)

    if @cart_items.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end

    reconcile_delivery_method

    active_methods = DeliveryMethod.where(active: true)
    if active_methods.exists? && @delivery_method.nil?
      redirect_to cart_path, alert: "Please select a delivery method."
      return
    end

    if @delivery_method&.address_required?
      cart_addr = Current.user.cart_address
      profile_addr = Current.user.address
      addr = {
        street_address: cart_addr&.street_address || profile_addr&.street_address,
        city:           cart_addr&.city           || profile_addr&.city,
        postal_code:    cart_addr&.postal_code    || profile_addr&.postal_code,
        country:        cart_addr&.country        || profile_addr&.country
      }
      if addr[:street_address].blank? || addr[:city].blank? || addr[:postal_code].blank? || addr[:country].blank?
        redirect_to cart_path, alert: "Please provide a delivery address."
        return
      end
    end

    reconcile_discount_code

    # Calculate totals (same formula as CartsController#show)
    subtotal_cents = @cart_items.sum(&:effective_price_cents)
    taxable_cents  = @cart_items.sum { |item| item.listing.tax_exempt? ? 0 : item.effective_price_cents }
    tax_cents      = (taxable_cents * SALES_TAX_RATE).ceil
    pretax_total   = subtotal_cents + tax_cents

    discount_cents = if @discount_code
      if @discount_code.fixed?
        [ @discount_code.amount_cents, pretax_total ].min
      else
        (pretax_total * @discount_code.amount_cents / 10_000.0).floor
      end
    else
      0
    end

    delivery_cents = @delivery_method&.price_cents || 0
    total_cents    = [ pretax_total - discount_cents + delivery_cents, 0 ].max

    # Build address snapshot
    cart_addr    = Current.user.cart_address
    profile_addr = Current.user.address

    order = Current.user.orders.build(
      delivery_method:      @delivery_method,
      delivery_method_name: @delivery_method&.name,
      delivery_price_cents: delivery_cents,
      discount_code:        @discount_code,
      discount_code_key:    @discount_code&.key,
      discount_cents:       discount_cents,
      subtotal_cents:       subtotal_cents,
      tax_cents:            tax_cents,
      total_cents:          total_cents,
      street_address:       cart_addr&.street_address || profile_addr&.street_address,
      city:                 cart_addr&.city           || profile_addr&.city,
      province:             cart_addr&.province       || profile_addr&.province,
      postal_code:          cart_addr&.postal_code    || profile_addr&.postal_code,
      country:              cart_addr&.country        || profile_addr&.country
    )

    @cart_items.each do |item|
      order.order_items.build(
        listing:         item.listing,
        name:            item.listing.name,
        price_cents:     item.effective_price_cents,
        listing_type:    item.listing.listing_type,
        rental_start_at: item.rental_start_at,
        rental_end_at:   item.rental_end_at
      )
    end

    ActiveRecord::Base.transaction do
      order.save!
    end

    Current.user.cart_items.destroy_all
    session.delete(:delivery_method_id)
    session.delete(:discount_code_id)

    redirect_to order_path(order), notice: "Your order has been placed!"
  rescue ActiveRecord::RecordInvalid
    redirect_to cart_path, alert: "There was a problem placing your order. Please try again."
  end

  def show
    @order = Current.user.orders.includes(:order_items).find(params[:id])
  end

  private

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
