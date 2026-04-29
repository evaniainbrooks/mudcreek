class SyncSquarePosPaymentService
  PLACEHOLDER_EMAIL_PREFIX = "pos-anonymous-".freeze

  def self.call(payment_data:, tenant:)
    new(payment_data:, tenant:).call
  end

  def initialize(payment_data:, tenant:)
    @payment_data = payment_data
    @tenant       = tenant
  end

  def call
    return if Order.unscoped.exists?(square_payment_id: @payment_data["id"])

    ActiveRecord::Base.transaction do
      order = Order.create!(build_order_attrs)
      build_order_items(order)
      order.transactions.create!(
        amount_cents:      @payment_data.dig("amount_money", "amount"),
        state:             :succeeded,
        square_payment_id: @payment_data["id"],
        raw_response:      @payment_data
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("SyncSquarePosPaymentService failed for payment #{@payment_data["id"]}: #{e.message}")
  end

  private

  def build_order_attrs
    user, guest_email = resolve_user_and_email

    {
      source:               :pos,
      status:               :paid,
      subtotal_cents:       subtotal_cents,
      tax_cents:            tax_cents,
      total_cents:          total_cents,
      delivery_price_cents: 0,
      discount_cents:       0,
      square_payment_id:    @payment_data["id"],
      user:,
      guest_email:          user ? nil : guest_email
    }
  end

  def resolve_user_and_email
    customer_id = @payment_data["customer_id"]
    return [ nil, placeholder_email ] if customer_id.blank?

    response = SquareClient.client.customers.get(customer_id:)
    customer = response.customer
    return [ nil, placeholder_email ] if customer.nil?

    email = customer.email_address.presence
    user  = email ? User.find_by(email:) : nil
    [ user, email || placeholder_email ]
  rescue Square::Errors::ResponseError => e
    Rails.logger.warn("Could not fetch Square customer #{customer_id}: #{e.message}")
    [ nil, placeholder_email ]
  end

  def build_order_items(order)
    items = square_line_items

    if items.any?
      items.each do |item|
        order.order_items.create!(
          name:         item[:name],
          price_cents:  item[:price_cents],
          listing_type: "sale"
        )
      end
    else
      order.order_items.create!(
        name:         "POS Sale",
        price_cents:  total_cents,
        listing_type: "sale"
      )
    end
  end

  def square_line_items
    square_order_id = @payment_data["order_id"]
    return [] if square_order_id.blank?

    response = SquareClient.client.orders.get(order_id: square_order_id)
    sq_order = response.order
    return [] if sq_order.nil? || sq_order.line_items.blank?

    sq_order.line_items.map do |item|
      {
        name:        [ item.name, item.variation_name ].compact.join(" – "),
        price_cents: item.base_price_money&.amount.to_i
      }
    end
  rescue Square::Errors::ResponseError => e
    Rails.logger.warn("Could not fetch Square order #{square_order_id}: #{e.message}")
    []
  end

  def total_cents
    @payment_data.dig("amount_money", "amount").to_i
  end

  def tax_cents
    @payment_data.dig("total_tax_money", "amount").to_i
  end

  def subtotal_cents
    total_cents - tax_cents
  end

  def placeholder_email
    @placeholder_email ||= "#{PLACEHOLDER_EMAIL_PREFIX}#{SecureRandom.hex(6)}@pos.local"
  end
end
