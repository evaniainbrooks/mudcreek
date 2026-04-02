class RecordManualSaleService
  Result = Data.define(:order, :error) do
    def success? = error.nil?
  end

  def self.call(listing:, quantity:, unit_price_cents:, buyer_name:, buyer_email: nil, notes: nil)
    order = nil

    ActiveRecord::Base.transaction do
      total_cents = quantity * unit_price_cents

      order = Order.create!(
        status:               :paid,
        guest_name:           buyer_name,
        guest_email:          buyer_email.presence || "cash-#{SecureRandom.hex(6)}@offline.local",
        subtotal_cents:       total_cents,
        tax_cents:            0,
        total_cents:          total_cents,
        delivery_price_cents: 0,
        discount_cents:       0,
        admin_notes:          notes.presence
      )

      item = order.order_items.create!(
        listing:      listing,
        name:         listing.name,
        price_cents:  total_cents,
        listing_type: "sale"
      )

      unless listing.unlimited_quantity?
        listing.stock_movements.create!(
          kind:             :stock_out,
          reason:           :manual_sale,
          quantity:         quantity,
          unit_price_cents: unit_price_cents,
          transacted_on:    Date.today,
          order_item:       item
        )
      end
    end

    Result.new(order:, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(order: nil, error: e.message)
  end
end
