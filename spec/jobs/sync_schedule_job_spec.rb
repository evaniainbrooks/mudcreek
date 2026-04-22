require "rails_helper"

RSpec.describe SyncScheduleJob, type: :job do
  let!(:tenant)   { Current.tenant = create(:tenant) }
  let(:location)  { create(:location) }
  let(:schedule)  { Schedule.create!(location: location, source_url: "https://example.com/calendar.ics") }
  let(:ical_data) { "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nEND:VCALENDAR\r\n" }

  after { Current.tenant = nil }

  describe "#perform" do
    context "with an https source URL" do
      before do
        allow(URI).to receive(:open).with("https://example.com/calendar.ics").and_return(StringIO.new(ical_data))
      end

      it "calls IcalImportService with the fetched data" do
        service = instance_double(IcalImportService, import: true)
        allow(IcalImportService).to receive(:new).with(schedule, ical_data).and_return(service)

        described_class.new.perform(schedule.id)

        expect(service).to have_received(:import)
      end

      it "resets Current.tenant to nil after the job completes" do
        allow(IcalImportService).to receive(:new).and_return(instance_double(IcalImportService, import: true))

        described_class.new.perform(schedule.id)

        expect(Current.tenant).to be_nil
      end
    end

    context "with a webcal:// source URL" do
      let(:schedule) { Schedule.create!(location: location, source_url: "webcal://example.com/calendar.ics") }

      it "opens the URL as https://" do
        allow(IcalImportService).to receive(:new).and_return(instance_double(IcalImportService, import: true))
        allow(URI).to receive(:open).with("https://example.com/calendar.ics").and_return(StringIO.new(ical_data))

        described_class.new.perform(schedule.id)

        expect(URI).to have_received(:open).with("https://example.com/calendar.ics")
      end

      it "does not attempt to open the original webcal:// URL" do
        allow(IcalImportService).to receive(:new).and_return(instance_double(IcalImportService, import: true))
        allow(URI).to receive(:open).with("https://example.com/calendar.ics").and_return(StringIO.new(ical_data))

        expect(URI).not_to receive(:open).with("webcal://example.com/calendar.ics")

        described_class.new.perform(schedule.id)
      end
    end

    context "when source_url is blank" do
      let(:schedule) { Schedule.create!(location: location, source_url: nil) }

      it "does not open any URL" do
        expect(URI).not_to receive(:open)

        described_class.new.perform(schedule.id)
      end
    end

    context "when the schedule does not exist" do
      it "does nothing" do
        expect(URI).not_to receive(:open)

        described_class.new.perform(0)
      end
    end
  end
end
