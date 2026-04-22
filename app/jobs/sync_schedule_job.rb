class SyncScheduleJob < ApplicationJob
  queue_as :default

  def perform(schedule_id)
    schedule = Schedule.unscoped.includes(location: :tenant).find_by(id: schedule_id)
    return if schedule.nil? || schedule.source_url.blank?

    Current.tenant = schedule.location.tenant

    require "open-uri"
    data = URI.open(schedule.source_url).read
    IcalImportService.new(schedule, data).import
  ensure
    Current.tenant = nil
  end
end
