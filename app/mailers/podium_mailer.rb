class PodiumMailer < ActionMailer::Base
  PODIUM_CONTACT_TO = "evaniainbrooks@gmail.com"

  layout "mailer"

  def contact(params)
    @name        = params[:name]
    @email       = params[:email]
    @message     = params[:message]
    @tenant_name = params[:tenant_name]
    @user_agent  = params[:user_agent]
    @user_id     = params[:user_id]
    @user_name   = params[:user_name]
    @submitted_at = params[:submitted_at]

    mail(
      to:       PODIUM_CONTACT_TO,
      from:     PODIUM_CONTACT_TO,
      reply_to: @email.presence || PODIUM_CONTACT_TO,
      subject:  "Podium contact from #{@name.presence || @email.presence || 'anonymous'}"
    )
  end
end
