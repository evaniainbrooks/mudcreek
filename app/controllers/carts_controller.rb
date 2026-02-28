class CartsController < ApplicationController
  def show
    @cart_items = Current.user.cart_items.includes(:listing).order(:created_at)

    remove_sold_items
    reconcile_discount_code

    subtotal_cents = @cart_items.sum { |item| item.listing.price_cents }
    taxable_cents  = @cart_items.sum { |item| item.listing.tax_exempt? ? 0 : item.listing.price_cents }
    tax_cents      = (taxable_cents * SALES_TAX_RATE).ceil
    pretax_total   = subtotal_cents + tax_cents

    discount_cents = if @discount_code
      if @discount_code.fixed?
        [@discount_code.amount_cents, pretax_total].min
      else
        (pretax_total * @discount_code.amount_cents / 10_000.0).floor
      end
    else
      0
    end

    @subtotal         = Money.new(subtotal_cents)
    @tax              = Money.new(tax_cents)
    @discount_savings = Money.new(discount_cents)
    @total            = Money.new([pretax_total - discount_cents, 0].max)
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
end
