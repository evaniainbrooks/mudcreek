class AuctionMailerPreview < ActionMailer::Preview
  def registration_pending
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    registration = AuctionRegistration.includes(:auction, :user).first!
    AuctionMailer.registration_pending(registration)
  end

  def registration_approved
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    registration = AuctionRegistration.includes(:auction, :user).first!
    AuctionMailer.registration_approved(registration)
  end
end
