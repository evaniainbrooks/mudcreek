class ApplicationMailer < ActionMailer::Base
  default from: -> { Current.tenant.email_address }
  layout "mailer"
end
