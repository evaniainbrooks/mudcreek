class RegistrationsMailer < ApplicationMailer
  def activate(user)
    @user = user
    mail subject: "Activate your account", to: user.email_address
  end

  def user_registered(user)
    @user = user
    mail subject: "New user registration: #{user.name}", to: user.tenant.email_address
  end
end
