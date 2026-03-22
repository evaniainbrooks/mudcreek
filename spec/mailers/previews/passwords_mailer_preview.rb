class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    user = User.first!
    PasswordsMailer.reset(user)
  end
end
