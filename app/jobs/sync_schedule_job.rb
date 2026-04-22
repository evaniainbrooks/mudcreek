class SyncScheduleJob < ApplicationJob
  queue_as :default

  def perform(schedule_id)
    schedule = Schedule.unscoped.includes(location: :tenant).find_by(id: schedule_id)
    return if schedule.nil? || schedule.source_url.blank?

    Current.tenant = schedule.location.tenant

    require "open-uri"
    url = schedule.source_url.sub(/\Awebcal:/i, "https:")
    data = URI.open(url).read
    IcalImportService.new(schedule, data).import
  ensure
    Current.tenant = nil
  end
end
