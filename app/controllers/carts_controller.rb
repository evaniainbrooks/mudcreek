class CartsController < ApplicationController
  allow_unauthenticated_access

  def show
    if Current.user
      @cart_items = Current.user.cart_items.includes(
        variant: [ { gallery: { photos_attachments: :blob } }, { option_values: :option } ],
        listing: [ { gallery: { photos_attachments: :blob } }, { auction_listing: :auction } ]
      ).order(:created_at)
    else
      token = session[:guest_cart_token]
      @cart_items = token ? CartItem.where(guest_cart_token: token).includes(
        variant: [ { gallery: { photos_attachments: :blob } }, { option_values: :option } ],
        listing: [ { gallery: { photos_attachments: :blob } }, { auction_listing: :auction } ]
      ).order(:created_at) : CartItem.none
    end

    remove_sold_items
    reconcile_discount_code
    reconcile_delivery_method
    build_cart_address

    @has_physical_items = @cart_items.any? { |item| item.listing.requires_delivery? }

    unless Current.user
      @guest_email = session[:guest_email]
      @guest_name  = session[:guest_name]
      @guest_info_saved = @guest_email.present? && @guest_name.present?
    end

    @cart_summary = CartCalculator.new(
      @cart_items, discount_code: @discount_code, delivery_method: @delivery_method
    ).calculate
  end

  private

  def remove_sold_items
    sold = @cart_items.select { |item| item.listing.sold? && !item.from_invoice? }
    return if sold.empty?

    sold_ids = sold.map(&:id)
    RentalBooking.where(cart_item_id: sold_ids).update_all(cart_item_id: nil)
    CartItem.where(id: sold_ids).delete_all
    @cart_items = @cart_items.reject { |item| item.listing.sold? }

    names = sold.map { |item| item.listing.name }.to_sentence
    flash.now[:alert] = t(".items_sold", count: sold.size, names: names)
  end

  def reconcile_discount_code
    return unless session[:discount_code_id]

    code = DiscountCode.find_by(id: session[:discount_code_id])

    if code.nil? || !code.active?
      session.delete(:discount_code_id)
      msg = code ? t(".discount_code_inactive", key: code.key) : t(".discount_code_invalid")
      flash.now[:alert] = [ flash.now[:alert], msg ].compact.join(" ")
      @discount_code = nil
    else
      @discount_code = code
    end
  end

  def build_cart_address
    if Current.user
      cart_addr = Current.user.cart_address
      profile_addr = Current.user.address
      @cart_address_saved = cart_addr&.street_address.present?
      @cart_address = {
        street_address: cart_addr&.street_address || profile_addr&.street_address,
        city:           cart_addr&.city           || profile_addr&.city,
        province:       cart_addr&.province       || profile_addr&.province,
        postal_code:    cart_addr&.postal_code    || profile_addr&.postal_code,
        country:        cart_addr&.country        || profile_addr&.country || "CA"
      }
    else
      guest_addr = session[:guest_address] || {}
      @cart_address_saved = guest_addr[:street_address].present?
      @cart_address = {
        street_address: guest_addr[:street_address],
        city:           guest_addr[:city],
        province:       guest_addr[:province],
        postal_code:    guest_addr[:postal_code],
        country:        guest_addr[:country] || "CA"
      }
    end
  end

  def reconcile_delivery_method
    return unless session[:delivery_method_id]

    method = DeliveryMethod.find_by(id: session[:delivery_method_id])

    if method.nil? || !method.active?
      session.delete(:delivery_method_id)
      flash.now[:alert] = [ flash.now[:alert], t(".delivery_method_unavailable") ].compact.join(" ")
      @delivery_method = nil
    else
      @delivery_method = method
    end
  end
end
