class SyncAllLocationCalendarsJob < ApplicationJob
  queue_as :default

  def perform
    Location.where.not(ical_url: [ nil, "" ]).find_each do |location|
      SyncLocationCalendarJob.perform_later(location.id, location.tenant_id)
    end
  end
end
