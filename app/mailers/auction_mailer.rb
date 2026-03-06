class AuctionMailer < ApplicationMailer
  def registration_pending(registration)
    @registration = registration
    @auction = registration.auction
    @user = registration.user

    mail(
      to: @auction.effective_admin_email_address,
      subject: "New registration pending: #{@auction.name}"
    )
  end
end
