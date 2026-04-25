class ScheduleEventsCalendarService
  # Duck-types as an icalendar event for LocationScheduleComponent.
  # dtstart/dtend return TimeWithZone (or Date for all-day) so the component
  # can call .hour, .min, .strftime, and .to_date on them.
  class Adapter
    def initialize(event)
      @event = event
    end

    def id          = @event.id
    def summary     = @event.summary
    def description = @event.description
    def all_day?    = @event.all_day?
    def rrule       = []

    def dtstart
      @event.all_day? ? @event.starts_at.utc.to_date : @event.starts_at.in_time_zone
    end

    def dtend
      @event.all_day? ? @event.ends_at&.utc&.to_date : @event.ends_at&.in_time_zone
    end
  end

  def initialize(schedule)
    @schedule = schedule
  end

  def today_events
    today = Date.current
    events_on_date(today).sort_by { |a| time_of_day_sort_key(a) }
  end

  def week_events(week_start)
    week_days = (0..6).map { |d| week_start + d.days }
    result    = week_days.index_with { [] }

    week_days.each do |day|
      result[day] = events_on_date(day).sort_by { |a| time_of_day_sort_key(a) }
    end

    result
  end

  private

  def time_of_day_sort_key(event)
    return [-1] if event.all_day?
    dt = event.dtstart
    [0, dt.hour * 60 + dt.min]
  rescue
    [0, 0]
  end

  def all_events
    @all_events ||= @schedule.schedule_events.to_a
  end

  def events_on_date(date)
    all_events
      .select { |e| occurs_on_date?(e, date) }
      .map    { |e| Adapter.new(e) }
  end

  def occurs_on_date?(event, date)
    return false unless event.starts_at

    event_date = event.all_day? ? event.starts_at.utc.to_date : event.starts_at.in_time_zone.to_date
    return false if event_date > date
    return event_date == date if event.rrule.blank?

    rrule_occurs_on?(event.rrule, event_date, date)
  end

  def rrule_occurs_on?(rrule_str, dtstart_date, target)
    parts    = rrule_str.split(";").filter_map { |p| p.split("=", 2) }.to_h
    freq     = parts["FREQ"].to_s.upcase
    interval = [parts["INTERVAL"].to_i, 1].max

    if (until_str = parts["UNTIL"].presence)
      until_date = Date.parse(until_str) rescue nil
      return false if until_date && target > until_date
    end

    case freq
    when "DAILY"
      diff = (target - dtstart_date).to_i
      diff >= 0 && diff % interval == 0
    when "WEEKLY"
      day_map = { "SU" => 0, "MO" => 1, "TU" => 2, "WE" => 3, "TH" => 4, "FR" => 5, "SA" => 6 }
      by_day  = (parts["BYDAY"] || "").split(",").filter_map { |d| day_map[d[-2..]] }
      wday_ok = by_day.any? ? by_day.include?(target.wday) : target.wday == dtstart_date.wday
      return false unless wday_ok

      diff_weeks = (target - dtstart_date).to_i / 7
      diff_weeks >= 0 && diff_weeks % interval == 0
    when "MONTHLY"
      return false unless target.day == dtstart_date.day

      diff = (target.year * 12 + target.month) - (dtstart_date.year * 12 + dtstart_date.month)
      diff >= 0 && diff % interval == 0
    when "YEARLY"
      target.month == dtstart_date.month && target.day == dtstart_date.day
    else
      false
    end
  end
end
