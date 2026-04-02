class RecordManualSaleService
  Result = Data.define(:order, :error) do
    def success? = error.nil?
  end

  def self.call(listing:, quantity:, unit_price_cents:, buyer_name: nil, buyer_email: nil, user_id: nil, sold_on: Date.today, notes: nil)
    order = nil

    ActiveRecord::Base.transaction do
      subtotal_cents = quantity * unit_price_cents
      tax_cents      = listing.tax_exempt? ? 0 : (subtotal_cents * SALES_TAX_RATE).ceil

      order_attrs = {
        status:               :paid,
        source:               :manual,
        subtotal_cents:       subtotal_cents,
        tax_cents:            tax_cents,
        total_cents:          subtotal_cents + tax_cents,
        delivery_price_cents: 0,
        discount_cents:       0,
        admin_notes:          notes.presence
      }

      if user_id.present?
        order_attrs[:user_id] = user_id
      else
        order_attrs[:guest_name]  = buyer_name
        order_attrs[:guest_email] = buyer_email.presence || "cash-#{SecureRandom.hex(6)}@offline.local"
      end

      order = Order.create!(**order_attrs)

      item = order.order_items.create!(
        listing:      listing,
        name:         listing.name,
        price_cents:  subtotal_cents,
        listing_type: "sale"
      )

      unless listing.unlimited_quantity?
        listing.stock_movements.create!(
          kind:             :stock_out,
          reason:           :manual_sale,
          quantity:         quantity,
          unit_price_cents: unit_price_cents,
          transacted_on:    sold_on,
          order_item:       item
        )
      end
    end

    Result.new(order:, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(order: nil, error: e.message)
  end
end
