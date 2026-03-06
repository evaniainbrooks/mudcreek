class ListingMailer < ApplicationMailer
  def offer_received(offer)
    @offer = offer
    @listing = offer.listing
    @buyer = offer.user

    mail(
      to: @listing.owner.email_address,
      subject: "New offer on #{@listing.name}"
    )
  end
end
