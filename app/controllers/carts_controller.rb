class CartsController < ApplicationController
  def show
    @cart_items = Current.user.cart_items.includes(:listing).order(:created_at)

    subtotal_cents = @cart_items.sum { |item| item.listing.price_cents }
    taxable_cents  = @cart_items.sum { |item| item.listing.tax_exempt? ? 0 : item.listing.price_cents }
    tax_cents      = (taxable_cents * SALES_TAX_RATE).ceil

    @subtotal = Money.new(subtotal_cents)
    @tax      = Money.new(tax_cents)
    @total    = Money.new(subtotal_cents + tax_cents)
  end
end
