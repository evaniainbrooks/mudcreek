class TaxCalculator
  LineItem = Data.define(:amount_cents, :tax_exempt) do
    def tax_exempt? = tax_exempt
  end

  def initialize(line_items, tax_rate)
    @line_items = line_items
    @tax_rate   = tax_rate
  end

  def tax_cents
    return 0 if @tax_rate <= 0
    taxable_cents = @line_items.reject(&:tax_exempt?).sum(&:amount_cents)
    (taxable_cents * @tax_rate).ceil
  end
end
