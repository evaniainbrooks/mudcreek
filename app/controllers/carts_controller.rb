class CartsController < ApplicationController
  def show
    @cart_items = Current.user.cart_items.includes(listing: { images_attachments: :blob }).order(:created_at)

    remove_sold_items
    reconcile_discount_code
    reconcile_delivery_method
    build_cart_address

    @cart_summary = CartCalculator.new(
      @cart_items, discount_code: @discount_code, delivery_method: @delivery_method
    ).calculate
  end

  private

  def remove_sold_items
    sold = @cart_items.select { |item| item.listing.sold? }
    return if sold.empty?

    sold.each(&:destroy)
    @cart_items = @cart_items.reject { |item| item.listing.sold? }

    names = sold.map { |item| item.listing.name }.to_sentence
    flash.now[:alert] = "#{names} #{sold.one? ? 'has' : 'have'} been sold and removed from your cart."
  end

  def reconcile_discount_code
    return unless session[:discount_code_id]

    code = DiscountCode.find_by(id: session[:discount_code_id])

    if code.nil? || !code.active?
      session.delete(:discount_code_id)
      flash.now[:alert] = [
        flash.now[:alert],
        code ? "Discount code \"#{code.key}\" is no longer active." : "Your discount code is no longer valid."
      ].compact.join(" ")
      @discount_code = nil
    else
      @discount_code = code
    end
  end

  def build_cart_address
    cart_addr = Current.user.cart_address
    profile_addr = Current.user.address
    @cart_address = {
      street_address: cart_addr&.street_address || profile_addr&.street_address,
      city:           cart_addr&.city           || profile_addr&.city,
      province:       cart_addr&.province       || profile_addr&.province,
      postal_code:    cart_addr&.postal_code    || profile_addr&.postal_code,
      country:        cart_addr&.country        || profile_addr&.country || "CA"
    }
  end

  def reconcile_delivery_method
    return unless session[:delivery_method_id]

    method = DeliveryMethod.find_by(id: session[:delivery_method_id])

    if method.nil? || !method.active?
      session.delete(:delivery_method_id)
      flash.now[:alert] = [ flash.now[:alert], "Your delivery method is no longer available." ].compact.join(" ")
      @delivery_method = nil
    else
      @delivery_method = method
    end
  end
end
