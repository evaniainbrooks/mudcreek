class RegistrationsMailerPreview < ActionMailer::Preview
  def activate
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    user = User.first!
    RegistrationsMailer.activate(user)
  end
end
