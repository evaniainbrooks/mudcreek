class LocationScheduleComponent < ViewComponent::Base
  attr_reader :location, :week_start, :week_days, :today, :slots, :grid, :view

  SLOTS = (0..31).map do |i|
    hour = 6 + i / 2
    min  = (i % 2) * 30
    h12  = hour > 12 ? hour - 12 : hour
    ampm = hour < 12 ? "AM" : "PM"
    { hour: hour, min: min, label: min.zero? ? "#{h12} #{ampm}" : nil }
  end.freeze

  EVENT_COLORS = [
    # --- Tier 1: Max contrast (use these first) ---
    { bg: "#dbeafe", border: "#60a5fa", text: "#1e3a8a" }, # blue
    { bg: "#dcfce7", border: "#4ade80", text: "#14532d" }, # green
    { bg: "#fef9c3", border: "#facc15", text: "#713f12" }, # yellow
    { bg: "#fce7f3", border: "#f472b6", text: "#831843" }, # pink
    { bg: "#ede9fe", border: "#a78bfa", text: "#4c1d95" }, # purple
    { bg: "#ffedd5", border: "#fb923c", text: "#7c2d12" }, # orange
    { bg: "#e0f2fe", border: "#38bdf8", text: "#075985" }, # sky
    { bg: "#ecfeff", border: "#22d3ee", text: "#164e63" }, # cyan

    # --- Tier 2: Strong but slightly softer ---
    { bg: "#f0fdfa", border: "#2dd4bf", text: "#134e4a" }, # teal
    { bg: "#ecfdf5", border: "#34d399", text: "#065f46" }, # emerald
    { bg: "#f7fee7", border: "#a3e635", text: "#365314" }, # lime
    { bg: "#fff1f2", border: "#fb7185", text: "#881337" }, # rose
    { bg: "#fdf4ff", border: "#e879f9", text: "#701a75" }, # fuchsia
    { bg: "#eef2ff", border: "#818cf8", text: "#312e81" }, # indigo
    { bg: "#eff6ff", border: "#3b82f6", text: "#1d4ed8" }, # alt blue
    { bg: "#f0f9ff", border: "#0ea5e9", text: "#0c4a6e" }, # deeper sky

    # --- Tier 3: Warmer / less saturated but still useful ---
    { bg: "#fefce8", border: "#fde68a", text: "#854d0e" }, # soft yellow
    { bg: "#fff7ed", border: "#fdba74", text: "#9a3412" }, # soft orange
    { bg: "#fdf2f8", border: "#f9a8d4", text: "#9d174d" }, # soft pink
    { bg: "#f5f3ff", border: "#c4b5fd", text: "#5b21b6" }, # soft violet

    # --- Tier 4: Neutrals / fallback ---
    { bg: "#f8fafc", border: "#cbd5f5", text: "#334155" }, # slate
    { bg: "#f9fafb", border: "#d1d5db", text: "#374151" }, # gray
    { bg: "#fafaf9", border: "#d6d3d1", text: "#44403c" }, # stone
    { bg: "#fef2f2", border: "#fca5a5", text: "#7f1d1d" }  # soft red
  ].freeze

  def initialize(location:, view: "weekly")
    @view          = view
    @location      = location
    @week_start    = Date.current.beginning_of_week(:sunday)
    @week_days     = (0..6).map { |d| @week_start + d.days }
    @today         = Date.current
    @slots         = SLOTS
    @grid          = build_grid if weekly?
    @color_index   = {}
    @color_counter = 0
  end

  def daily?
    @view == "daily"
  end

  def weekly?
    @view == "weekly"
  end

  def today_events
    @today_events ||= LocationCalendarService.new(@location).today_events
  end

  def today_col_idx
    @week_days.index(@today)
  end

  def primary_color
    Current.tenant.primary_color.presence || "#355E3B"
  end

  def primary_color_tint(amount = 0.85)
    hex = primary_color.delete("#")
    r, g, b = hex.scan(/../).map { |c| c.to_i(16) }
    r2 = (r + (255 - r) * amount).round
    g2 = (g + (255 - g) * amount).round
    b2 = (b + (255 - b) * amount).round
    "#%02x%02x%02x" % [r2, g2, b2]
  end

  def color_for(title)
    @color_index[title] ||= begin
      c = EVENT_COLORS[@color_counter % EVENT_COLORS.size]
      @color_counter += 1
      c
    end
  end

  def described_events
    @described_events ||= begin
      events = if daily?
        today_events
      else
        LocationCalendarService.new(@location).week_events(@week_start).values.flatten
      end
      events.select { |e| e.description.to_s.strip.present? }
            .uniq { |e| e.summary.to_s.strip.downcase }
            .sort_by { |e| e.summary.to_s }
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
