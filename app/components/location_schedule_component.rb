class LocationScheduleComponent < ViewComponent::Base
  attr_reader :location, :week_start, :week_days, :today, :slots, :grid

  SLOTS = (0..31).map do |i|
    hour = 6 + i / 2
    min  = (i % 2) * 30
    h12  = hour > 12 ? hour - 12 : hour
    ampm = hour < 12 ? "AM" : "PM"
    { hour: hour, min: min, label: min.zero? ? "#{h12} #{ampm}" : nil }
  end.freeze

  def initialize(location:)
    @location   = location
    @week_start = Date.current.beginning_of_week(:sunday)
    @week_days  = (0..6).map { |d| @week_start + d.days }
    @today      = Date.current
    @slots      = SLOTS
    @grid       = build_grid
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
