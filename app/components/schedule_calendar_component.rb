class ScheduleCalendarComponent < ViewComponent::Base
  EVENT_COLORS = LocationScheduleComponent::EVENT_COLORS
  SLOTS        = LocationScheduleComponent::SLOTS

  attr_reader :schedule, :view, :week_start, :week_days, :today, :slots, :grid

  def initialize(schedule:, view: "weekly")
    @schedule      = schedule
    @view          = view
    @week_start    = Date.current.beginning_of_week(:sunday)
    @week_days     = (0..6).map { |d| @week_start + d.days }
    @today         = Date.current
    @slots         = SLOTS
    @grid          = build_grid if weekly?
    @color_index   = {}
    @color_counter = 0
  end

  def daily?  = @view == "daily"
  def weekly? = @view == "weekly"

  def today_col_idx
    @week_days.index(@today)
  end

  def today_events
    @today_events ||= events_on_date(@today).sort_by { |e| e.starts_at || Time.at(0) }
  end

  def color_for(title)
    @color_index[title] ||= begin
      c = EVENT_COLORS[@color_counter % EVENT_COLORS.size]
      @color_counter += 1
      c
    end
  end

  private

  def all_events
    @all_events ||= schedule.schedule_events.to_a
  end

  def events_on_date(date)
    all_events.select { |e| occurs_on_date?(e, date) }
  end

  def build_grid
    @week_days.map do |day|
      events = events_on_date(day).sort_by { |e| e.starts_at || Time.at(0) }
      slots  = Array.new(32, :empty)

      events.each do |event|
        next unless event.starts_at && event.ends_at

        start_slot = ((event.starts_at.hour - 6) * 2 + event.starts_at.min / 30).clamp(0, 31)
        end_slot   = ((event.ends_at.hour   - 6) * 2 + event.ends_at.min   / 30).clamp(0, 32)
        rowspan    = end_slot - start_slot
        next if rowspan <= 0 || slots[start_slot] == :covered

        slots[start_slot] = { event: event, rowspan: rowspan }
        ((start_slot + 1)...[end_slot, 32].min).each { |s| slots[s] = :covered }
      rescue
        next
      end

      slots
    end
  end

  def occurs_on_date?(event, date)
    return false unless event.starts_at
    event_date = event.starts_at.to_date
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
