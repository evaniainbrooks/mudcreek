class ListingMailer < ApplicationMailer
  def offer_received(offer)
    @offer = offer
    @listing = offer.listing
    @buyer = offer.user

    mail(
      to: @listing.owner&.email_address,
      subject: "New offer on #{@listing.name}"
    )
  end

  def offer_accepted(invoice)
    @invoice = invoice
    @offer = invoice.offer
    @listing = @offer.listing
    @user = invoice.user

    mail(
      to: @user.email_address,
      subject: "Your offer on #{@listing.name} was accepted"
    )
  end
end
