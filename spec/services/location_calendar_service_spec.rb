require "rails_helper"

RSpec.describe LocationCalendarService do
  # Travel to a fixed Wednesday so recurrence assertions are deterministic.
  # 2026-03-25 is a Wednesday (wday 3).
  around { |ex| travel_to(Time.zone.local(2026, 3, 25, 10, 0, 0)) { ex.run } }

  let(:location) { build_stubbed(:location) }
  let(:attachment) { instance_double(ActiveStorage::Attached::One, attached?: true, download: ics_data) }

  before { allow(location).to receive(:calendar_file).and_return(attachment) }

  subject(:service) { described_class.new(location) }

  def build_ics(*events)
    lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Test//EN"]
    events.each do |ev|
      lines << "BEGIN:VEVENT"
      lines << "UID:#{SecureRandom.uuid}"
      lines << "SUMMARY:#{ev[:summary]}"
      lines << "DTSTART:#{ev[:dtstart]}"
      lines << "DTEND:#{ev.fetch(:dtend, ev[:dtstart])}"
      lines << "RRULE:#{ev[:rrule]}" if ev[:rrule]
      lines << "END:VEVENT"
    end
    lines << "END:VCALENDAR"
    lines.join("\n")
  end

  # ------------------------------------------------------------------ #
  context "when no calendar file is attached" do
    before { allow(attachment).to receive(:attached?).and_return(false) }
    let(:ics_data) { "" }

    it "returns an empty array" do
      expect(service.today_events).to eq([])
    end
  end

  # ------------------------------------------------------------------ #
  context "with a non-recurring event" do
    context "when the event starts today" do
      let(:ics_data) { build_ics(summary: "Morning Stand-up", dtstart: "20260325T090000Z") }

      it "includes the event" do
        expect(service.today_events.map(&:summary)).to contain_exactly("Morning Stand-up")
      end
    end

    context "when the event is on a different day" do
      let(:ics_data) { build_ics(summary: "Yesterday Meeting", dtstart: "20260324T090000Z") }

      it "returns an empty array" do
        expect(service.today_events).to be_empty
      end
    end

    context "when the event is in the future" do
      let(:ics_data) { build_ics(summary: "Future Event", dtstart: "20260326T090000Z") }

      it "returns an empty array" do
        expect(service.today_events).to be_empty
      end
    end
  end

  # ------------------------------------------------------------------ #
  context "with a weekly recurring event" do
    context "when BYDAY matches today (Wednesday)" do
      let(:ics_data) { build_ics(summary: "Weekly Wednesday", dtstart: "20240103T090000Z", rrule: "FREQ=WEEKLY;BYDAY=WE") }

      it "includes the event" do
        expect(service.today_events.map(&:summary)).to contain_exactly("Weekly Wednesday")
      end
    end

    context "when BYDAY does not match today" do
      let(:ics_data) { build_ics(summary: "Monday Only", dtstart: "20240101T090000Z", rrule: "FREQ=WEEKLY;BYDAY=MO") }

      it "returns an empty array" do
        expect(service.today_events).to be_empty
      end
    end

    context "with BYDAY covering multiple days including today" do
      let(:ics_data) { build_ics(summary: "Weekday Standup", dtstart: "20240101T090000Z", rrule: "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR") }

      it "includes the event" do
        expect(service.today_events.map(&:summary)).to contain_exactly("Weekday Standup")
      end
    end

    context "with INTERVAL=2 (biweekly) landing on today" do
      # dtstart Jan 3, 2024 (Wednesday). diff_weeks to Mar 25, 2026 = 116, which is even.
      let(:ics_data) { build_ics(summary: "Biweekly", dtstart: "20240103T090000Z", rrule: "FREQ=WEEKLY;INTERVAL=2;BYDAY=WE") }

      it "includes the event" do
        expect(service.today_events.map(&:summary)).to contain_exactly("Biweekly")
      end
    end

    context "with UNTIL before today" do
      let(:ics_data) { build_ics(summary: "Expired Weekly", dtstart: "20240103T090000Z", rrule: "FREQ=WEEKLY;BYDAY=WE;UNTIL=20260101") }

      it "returns an empty array" do
        expect(service.today_events).to be_empty
      end
    end
  end

  # ------------------------------------------------------------------ #
  context "with a monthly recurring event" do
    context "when the day-of-month matches today (25th)" do
      let(:ics_data) { build_ics(summary: "Monthly Review", dtstart: "20240125T140000Z", rrule: "FREQ=MONTHLY") }

      it "includes the event" do
        expect(service.today_events.map(&:summary)).to contain_exactly("Monthly Review")
      end
    end

    context "when the day-of-month does not match" do
      let(:ics_data) { build_ics(summary: "Monthly Other Day", dtstart: "20240110T140000Z", rrule: "FREQ=MONTHLY") }

      it "returns an empty array" do
        expect(service.today_events).to be_empty
      end
    end
  end

  # ------------------------------------------------------------------ #
  context "with a daily recurring event" do
    context "when dtstart is before today" do
      let(:ics_data) { build_ics(summary: "Daily Standup", dtstart: "20260301T080000Z", rrule: "FREQ=DAILY") }

      it "includes the event" do
        expect(service.today_events.map(&:summary)).to contain_exactly("Daily Standup")
      end
    end
  end

  # ------------------------------------------------------------------ #
  context "with a yearly recurring event" do
    context "when month and day match today (March 25)" do
      let(:ics_data) { build_ics(summary: "Annual Event", dtstart: "20240325T120000Z", rrule: "FREQ=YEARLY") }

      it "includes the event" do
        expect(service.today_events.map(&:summary)).to contain_exactly("Annual Event")
      end
    end

    context "when month or day does not match" do
      let(:ics_data) { build_ics(summary: "Other Annual", dtstart: "20240401T120000Z", rrule: "FREQ=YEARLY") }

      it "returns an empty array" do
        expect(service.today_events).to be_empty
      end
    end
  end

  # ------------------------------------------------------------------ #
  context "with multiple events" do
    let(:ics_data) do
      build_ics(
        { summary: "Today's Event",     dtstart: "20260325T090000Z" },
        { summary: "Yesterday's Event", dtstart: "20260324T090000Z" },
        { summary: "Weekly Wed",        dtstart: "20240103T100000Z", rrule: "FREQ=WEEKLY;BYDAY=WE" }
      )
    end

    it "returns only the events occurring today" do
      summaries = service.today_events.map(&:summary)
      expect(summaries).to contain_exactly("Today's Event", "Weekly Wed")
    end

    it "sorts events by dtstart" do
      summaries = service.today_events.map(&:summary)
      expect(summaries.first).to eq("Today's Event")
    end
  end

  # ------------------------------------------------------------------ #
  context "when the ICS data is malformed" do
    let(:ics_data) { "this is not valid icalendar data %%%" }

    it "returns an empty array" do
      expect(service.today_events).to eq([])
    end

    it "logs an error" do
      expect(Rails.logger).to receive(:error).with(/Calendar parse error/)
      service.today_events
    end
  end
end
