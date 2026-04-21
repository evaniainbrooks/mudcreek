class LocationAnnouncementMailer < ApplicationMailer
  def announce(user, announcement)
    @user         = user
    @announcement = announcement
    @location     = announcement.location
    mail(to: user.email_address, subject: announcement.subject)
  end
end
