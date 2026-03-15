class CreateLotSettlementJob < ApplicationJob
  queue_as :default

  def perform(listing_id, sale_context)
    listing = Listing.unscoped.find(listing_id)
    Current.tenant = listing.tenant
    lot = listing.lot
    return unless lot

    settlement = lot.settlement || lot.create_settlement!

    # Idempotency: skip if hammer_price line item already exists for this listing
    return if settlement.settlement_line_items
      .where(line_item_type: :hammer_price, listing_id: listing.id)
      .exists?

    hammer_price_cents = sale_context[:hammer_price_cents]

    settlement.settlement_line_items.create!(
      listing:       listing,
      line_item_type: :hammer_price,
      amount_cents:  hammer_price_cents,
      description:   "Hammer price \u2014 #{listing.name}"
    )

    if lot.commission_rate.present?
      rate = lot.commission_rate
      commission_cents = (hammer_price_cents * rate / 100.0).round
      settlement.settlement_line_items.create!(
        listing:       listing,
        line_item_type: :seller_commission,
        amount_cents:  commission_cents,
        description:   "Commission (#{rate}%) \u2014 #{listing.name}"
      )
    end

    if lot.seller_fee_cents.present?
      seller_fee_already_added = settlement.settlement_line_items
        .where(line_item_type: :seller_fee)
        .exists?

      unless seller_fee_already_added
        settlement.settlement_line_items.create!(
          line_item_type: :seller_fee,
          amount_cents:  lot.seller_fee_cents,
          description:   "Seller fee \u2014 #{lot.name}"
        )
      end
    end

    LotMailer.settlement_updated(settlement).deliver_later
  end
end
