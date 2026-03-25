class SyncLocationCalendarJob < ApplicationJob
  queue_as :default

  def perform(location_id, tenant_id)
    Current.tenant = Tenant.find(tenant_id)
    location = Location.find(location_id)
    return if location.ical_url.blank?

    require "open-uri"
    data = URI.open(location.ical_url).read
    location.calendar_file.attach(
      io: StringIO.new(data),
      filename: "calendar.ics",
      content_type: "text/calendar"
    )
  end
end
