require "rails_helper"

RSpec.describe IcalImportService do
  let!(:tenant)  { Current.tenant = create(:tenant) }
  let(:location) { create(:location) }
  let(:schedule) { Schedule.create!(location: location) }

  after { Current.tenant = nil }

  def perform(ics)
    described_class.new(schedule, ics).import
  end

  let(:basic_ics) do
    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      X-WR-CALNAME:Test Calendar
      BEGIN:VEVENT
      UID:abc-123
      SUMMARY:Team Meeting
      DTSTART:20260501T100000Z
      DTEND:20260501T110000Z
      END:VEVENT
      END:VCALENDAR
    ICS
  end

  let(:rrule_ics) do
    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      UID:recurring-1
      SUMMARY:Weekly Standup
      DTSTART:20260501T090000Z
      RRULE:FREQ=WEEKLY;BYDAY=MO
      END:VEVENT
      END:VCALENDAR
    ICS
  end

  let(:all_day_ics) do
    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      UID:allday-1
      SUMMARY:Holiday
      DTSTART;VALUE=DATE:20260525
      DTEND;VALUE=DATE:20260526
      END:VEVENT
      END:VCALENDAR
    ICS
  end

  describe "#import" do
    it "creates schedule events" do
      expect { perform(basic_ics) }.to change(ScheduleEvent, :count).by(1)
    end

    it "stores the event summary" do
      perform(basic_ics)
      expect(ScheduleEvent.last.summary).to eq("Team Meeting")
    end

    it "stores the uid" do
      perform(basic_ics)
      expect(ScheduleEvent.last.uid).to eq("abc-123")
    end

    it "sets the schedule name from X-WR-CALNAME when blank" do
      perform(basic_ics)
      expect(schedule.reload.name).to eq("Test Calendar")
    end

    it "updates last_synced_at" do
      freeze_time do
        perform(basic_ics)
        expect(schedule.reload.last_synced_at).to be_within(1.second).of(Time.current)
      end
    end

    context "with a recurring event (RRULE)" do
      it "stores the rrule string without raising" do
        expect { perform(rrule_ics) }.not_to raise_error
      end

      it "persists the rrule value" do
        perform(rrule_ics)
        expect(ScheduleEvent.last.rrule).to include("FREQ=WEEKLY")
      end
    end

    context "with an all-day event" do
      it "marks the event as all_day" do
        perform(all_day_ics)
        expect(ScheduleEvent.last.all_day).to be true
      end
    end

    context "with an empty calendar" do
      let(:empty_ics) { "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nEND:VCALENDAR\r\n" }

      it "does not raise" do
        expect { perform(empty_ics) }.not_to raise_error
      end

      it "creates no events" do
        expect { perform(empty_ics) }.not_to change(ScheduleEvent, :count)
      end
    end

    context "when run twice with the same data" do
      it "upserts rather than duplicating events" do
        perform(basic_ics)
        expect { perform(basic_ics) }.not_to change(ScheduleEvent, :count)
      end
    end

    context "when the feed contains duplicate UIDs" do
      let(:duplicate_uid_ics) do
        <<~ICS
          BEGIN:VCALENDAR
          VERSION:2.0
          BEGIN:VEVENT
          UID:dup-uid
          SUMMARY:First occurrence
          DTSTART:20260501T100000Z
          END:VEVENT
          BEGIN:VEVENT
          UID:dup-uid
          SUMMARY:Second occurrence
          DTSTART:20260502T100000Z
          END:VEVENT
          END:VCALENDAR
        ICS
      end

      it "does not raise a cardinality violation" do
        expect { perform(duplicate_uid_ics) }.not_to raise_error
      end

      it "creates only one event for the duplicated UID" do
        perform(duplicate_uid_ics)
        expect(ScheduleEvent.where(uid: "dup-uid").count).to eq(1)
      end
    end
  end
end
