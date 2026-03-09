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

  def registration_approved(registration)
    @registration = registration
    @auction = registration.auction
    @user = registration.user

    mail(
      to: @user.email_address,
      subject: "Your registration for #{@auction.name} has been approved"
    )
  end
end
