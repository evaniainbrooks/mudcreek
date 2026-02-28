class CartsController < ApplicationController
  def show
    @cart_items = Current.user.cart_items.includes(:listing).order(:created_at)

    subtotal_cents = @cart_items.sum { |item| item.listing.price_cents }
    taxable_cents  = @cart_items.sum { |item| item.listing.tax_exempt? ? 0 : item.listing.price_cents }
    tax_cents      = (taxable_cents * SALES_TAX_RATE).ceil
    pretax_total   = subtotal_cents + tax_cents

    @discount_code = DiscountCode.find_by(id: session[:discount_code_id])
    @discount_code = nil if @discount_code && !@discount_code.active?

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
end
