class LocationCalendarService
  def initialize(location)
    @location = location
  end

  def today_events
    return [] unless @location.calendar_file.attached?

    require "icalendar"
    now       = Time.current
    calendars = Icalendar::Calendar.parse(@location.calendar_file.download)
    calendars.flat_map(&:events)
             .select { |e| occurs_today?(e, now) }
             .sort_by { |e| [e.dtstart.hour, e.dtstart.min] rescue [0, 0] }
  rescue => e
    Rails.logger.error("Calendar parse error for location #{@location.id}: #{e.message}")
    []
  end

  def week_events(week_start)
    return {} unless @location.calendar_file.attached?

    require "icalendar"
    week_days  = (0..6).map { |d| week_start + d.days }
    calendars  = Icalendar::Calendar.parse(@location.calendar_file.download)
    all_events = calendars.flat_map(&:events)
    result     = week_days.index_with { [] }

    all_events.each do |event|
      week_days.each do |day|
        result[day] << event if occurs_on_date?(event, day)
      end
    end

    result.transform_values do |events|
      events.sort_by { |e| [e.dtstart.hour, e.dtstart.min] rescue [0, 0] }
    end
  rescue => e
    Rails.logger.error("Calendar parse error for location #{@location.id}: #{e.message}")
    {}
  end

  private

  def event_local_today(dtstart, now)
    tz_id = dtstart.ical_params["tzid"]&.first.presence
    tz_id ? now.in_time_zone(tz_id).to_date : now.utc.to_date
  rescue TZInfo::InvalidTimezoneIdentifier, ActiveSupport::TimeZoneNotFoundError
    now.utc.to_date
  end

  def occurs_today?(event, now)
    return false unless event.dtstart
    today = event_local_today(event.dtstart, now)
    occurs_on_date?(event, today)
  end

  def occurs_on_date?(event, target)
    return false unless event.dtstart
    dtstart_date = event.dtstart.to_date rescue nil
    return false unless dtstart_date
    return false if dtstart_date > target
    return dtstart_date == target if event.rrule.blank?
    event.rrule.any? { |rule| rrule_occurs_on?(rule, dtstart_date, target) }
  end

  def rrule_occurs_on?(rule, dtstart_date, today)
    if (until_val = rule.until)
      until_date = until_val.to_date rescue nil
      return false if until_date && today > until_date
    end

    freq     = rule.frequency.to_s.upcase
    interval = [rule.interval.to_i, 1].max

    case freq
    when "DAILY"
      diff = (today - dtstart_date).to_i
      diff >= 0 && diff % interval == 0
    when "WEEKLY"
      day_map  = { "SU" => 0, "MO" => 1, "TU" => 2, "WE" => 3, "TH" => 4, "FR" => 5, "SA" => 6 }
      by_day   = Array(rule.by_day).map { |d| day_map[d.to_s[-2..]] }.compact
      wday_ok  = by_day.any? ? by_day.include?(today.wday) : today.wday == dtstart_date.wday
      return false unless wday_ok
      diff_weeks = (today - dtstart_date).to_i / 7
      diff_weeks >= 0 && diff_weeks % interval == 0
    when "MONTHLY"
      return false unless today.day == dtstart_date.day
      diff_months = (today.year * 12 + today.month) - (dtstart_date.year * 12 + dtstart_date.month)
      diff_months >= 0 && diff_months % interval == 0
    when "YEARLY"
      today.month == dtstart_date.month && today.day == dtstart_date.day
    else
      false
    end
  end
end
