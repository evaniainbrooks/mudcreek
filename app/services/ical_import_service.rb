class IcalImportService
  def initialize(schedule, ics_content)
    @schedule    = schedule
    @ics_content = ics_content
  end

  def import
    require "icalendar"
    calendars = Icalendar::Calendar.parse(@ics_content)
    return if calendars.empty?

    cal = calendars.first
    @schedule.name ||= cal.x_wr_calname&.first.presence || "Calendar"

    rows = cal.events.filter_map { |e| build_row(e) }.uniq { |r| r[:uid] }
    ScheduleEvent.upsert_all(rows, unique_by: [:schedule_id, :uid]) if rows.any?

    @schedule.update_columns(name: @schedule.name, last_synced_at: Time.current)
  end

  private

  def build_row(event)
    uid = event.uid.to_s.strip
    return nil if uid.blank?

    starts_at, ends_at, all_day = parse_times(event)
    rrule_str = event.rrule.first&.value_ical.presence
    now = Time.current

    {
      tenant_id:   @schedule.tenant_id,
      schedule_id: @schedule.id,
      uid:         uid,
      summary:     event.summary.to_s.strip.presence,
      description: event.description.to_s.strip.presence,
      starts_at:   starts_at,
      ends_at:     ends_at,
      all_day:     all_day,
      rrule:       rrule_str,
      created_at:  now,
      updated_at:  now
    }
  end

  def parse_times(event)
    dtstart = event.dtstart
    dtend   = event.dtend
    all_day = dtstart.is_a?(Icalendar::Values::Date)

    starts_at = if all_day
      dtstart.to_date.beginning_of_day rescue nil
    else
      dtstart.to_time.utc rescue nil
    end

    ends_at = if dtend
      all_day ? (dtend.to_date.beginning_of_day rescue nil) : (dtend.to_time.utc rescue nil)
    end

    [starts_at, ends_at, all_day]
  end
end
