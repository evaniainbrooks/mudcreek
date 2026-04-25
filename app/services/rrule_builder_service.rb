class RruleBuilderService
  VALID_FREQS = %w[DAILY WEEKLY MONTHLY YEARLY].freeze

  def self.build(recurrence_params)
    p = (recurrence_params || {}).to_h.with_indifferent_access

    return p[:raw].presence if p[:advanced].in?(%w[1 true])

    freq = p[:freq].to_s.upcase
    return nil unless VALID_FREQS.include?(freq)

    parts = ["FREQ=#{freq}"]

    interval = p[:interval].to_i
    parts << "INTERVAL=#{interval}" if interval > 1

    if freq == "WEEKLY"
      byday = Array(p[:byday]).map(&:strip).select(&:present?).join(",")
      parts << "BYDAY=#{byday}" if byday.present?
    end

    if (until_str = p[:until].presence)
      parts << "UNTIL=#{until_str.delete('-')}"
    end

    parts.join(";")
  end

  def self.parse(rrule_str)
    return { freq: "", interval: 1, byday: [], until: "", advanced: false, raw: "" } if rrule_str.blank?

    parts = rrule_str.split(";").filter_map { |p| p.split("=", 2) }.to_h
    freq  = parts["FREQ"].to_s.upcase

    unless VALID_FREQS.include?(freq)
      return { freq: "", interval: 1, byday: [], until: "", advanced: true, raw: rrule_str }
    end

    until_raw  = parts["UNTIL"].presence
    until_date = until_raw ? "#{until_raw[0, 4]}-#{until_raw[4, 2]}-#{until_raw[6, 2]}" : ""

    {
      freq:     freq,
      interval: [parts["INTERVAL"].to_i, 1].max,
      byday:    (parts["BYDAY"] || "").split(",").map(&:strip).reject(&:empty?),
      until:    until_date,
      advanced: false,
      raw:      ""
    }
  end
end
