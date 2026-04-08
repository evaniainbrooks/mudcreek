class LocationScheduleComponent < ViewComponent::Base
  attr_reader :location, :week_start, :week_days, :today, :slots, :grid

  SLOTS = (0..31).map do |i|
    hour = 6 + i / 2
    min  = (i % 2) * 30
    h12  = hour > 12 ? hour - 12 : hour
    ampm = hour < 12 ? "AM" : "PM"
    { hour: hour, min: min, label: min.zero? ? "#{h12} #{ampm}" : nil }
  end.freeze

  EVENT_COLORS = [
    { bg: "#dbeafe", border: "#93c5fd", text: "#1e40af" },
    { bg: "#dcfce7", border: "#86efac", text: "#166534" },
    { bg: "#fef9c3", border: "#fde047", text: "#854d0e" },
    { bg: "#fce7f3", border: "#f9a8d4", text: "#9d174d" },
    { bg: "#ede9fe", border: "#c4b5fd", text: "#5b21b6" },
    { bg: "#ffedd5", border: "#fdba74", text: "#9a3412" },
    { bg: "#e0f2fe", border: "#7dd3fc", text: "#0c4a6e" },
    { bg: "#fdf2f8", border: "#e879f9", text: "#701a75" }
  ].freeze

  def initialize(location:)
    @location      = location
    @week_start    = Date.current.beginning_of_week(:sunday)
    @week_days     = (0..6).map { |d| @week_start + d.days }
    @today         = Date.current
    @slots         = SLOTS
    @grid          = build_grid
    @color_index   = {}
    @color_counter = 0
  end

  def today_col_idx
    @week_days.index(@today)
  end

  def primary_color
    Current.tenant.primary_color.presence || "#355E3B"
  end

  def color_for(title)
    @color_index[title] ||= begin
      c = EVENT_COLORS[@color_counter % EVENT_COLORS.size]
      @color_counter += 1
      c
    end
  end

  private

  def build_grid
    week_events = LocationCalendarService.new(@location).week_events(@week_start)

    @week_days.map do |day|
      events = week_events[day] || []
      slots  = Array.new(32, :empty)

      events.each do |event|
        next unless event.dtstart && event.dtend

        start_slot = ((event.dtstart.hour - 6) * 2 + event.dtstart.min / 30).clamp(0, 31)
        end_slot   = ((event.dtend.hour   - 6) * 2 + event.dtend.min   / 30).clamp(0, 32)
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
end
