class ListingMailerPreview < ActionMailer::Preview
  def offer_received
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    offer = Offer.includes(:listing, :user).first!
    ListingMailer.offer_received(offer)
  end

  def offer_accepted
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    invoice = Invoice.includes(offer: :listing, user: nil).where.not(offer_id: nil).first!
    ListingMailer.offer_accepted(invoice)
  end
end
