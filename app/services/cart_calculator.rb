class CartCalculator
  Result = Data.define(
    :subtotal_cents, :tax_cents, :discount_cents, :delivery_cents, :total_cents,
    :subtotal, :tax, :discount_savings, :delivery, :total
  )

  def initialize(cart_items, discount_code: nil, delivery_method: nil)
    @cart_items      = cart_items
    @discount_code   = discount_code
    @delivery_method = delivery_method
  end

  def calculate
    subtotal_cents = @cart_items.sum { |i| i.effective_price.cents }
    tax_line_items = @cart_items.map { |i| TaxCalculator::LineItem.new(amount_cents: i.effective_price.cents, tax_exempt: i.listing.tax_exempt?) }
    tax_cents      = TaxCalculator.new(tax_line_items, SALES_TAX_RATE).tax_cents
    pretax_total   = subtotal_cents + tax_cents
    discount_cents = compute_discount(pretax_total)
    delivery_cents = @delivery_method&.price_cents || 0
    total_cents    = [pretax_total - discount_cents + delivery_cents, 0].max

    Result.new(
      subtotal_cents:,  tax_cents:,  discount_cents:,  delivery_cents:,  total_cents:,
      subtotal:         Money.new(subtotal_cents),
      tax:              Money.new(tax_cents),
      discount_savings: Money.new(discount_cents),
      delivery:         Money.new(delivery_cents),
      total:            Money.new(total_cents)
    )
  end

  private

  def compute_discount(pretax_total)
    return 0 unless @discount_code
    if @discount_code.fixed?
      [@discount_code.amount_cents, pretax_total].min
    else
      (pretax_total * @discount_code.amount_cents / 10_000.0).floor
    end
  end
end
