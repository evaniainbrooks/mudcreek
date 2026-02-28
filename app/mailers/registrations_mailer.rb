class RegistrationsMailer < ApplicationMailer
  def activate(user)
    @user = user
    mail subject: "Activate your account", to: user.email_address
  end
end
