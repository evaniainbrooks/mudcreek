class SendLocationAnnouncementJob < ApplicationJob
  def perform(announcement_id)
    announcement = LocationAnnouncement.unscoped
                     .includes(location: [:users, :tenant])
                     .find_by(id: announcement_id)
    return unless announcement

    Current.tenant = announcement.location.tenant
    recipients = announcement.location.users
    count = recipients.count

    recipients.find_each do |user|
      LocationAnnouncementMailer.announce(user, announcement).deliver_now
    end

    announcement.update_columns(sent_at: Time.current, recipient_count: count)
  ensure
    Current.tenant = nil
  end
end
