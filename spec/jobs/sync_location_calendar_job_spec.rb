require "rails_helper"

RSpec.describe SyncLocationCalendarJob, type: :job do
  let!(:tenant) { Current.tenant = create(:tenant) }
  let(:ical_data) { "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nEND:VCALENDAR\r\n" }
  let(:location) { create(:location, ical_url: "https://example.com/feed.ics") }

  after { Current.tenant = nil }

  describe "#perform" do
    context "when the location has an ical_url" do
      before do
        allow(URI).to receive(:open).with(location.ical_url).and_return(StringIO.new(ical_data))
      end

      it "attaches calendar_file to the location" do
        described_class.new.perform(location.id, tenant.id)

        expect(location.reload.calendar_file).to be_attached
      end

      it "stores the fetched ical data" do
        described_class.new.perform(location.id, tenant.id)

        expect(location.reload.calendar_file.download).to eq(ical_data)
      end

      it "attaches with the correct content type" do
        described_class.new.perform(location.id, tenant.id)

        expect(location.reload.calendar_file.content_type).to eq("text/calendar")
      end

      it "attaches with the filename calendar.ics" do
        described_class.new.perform(location.id, tenant.id)

        expect(location.reload.calendar_file.filename.to_s).to eq("calendar.ics")
      end
    end

    context "when the location has no ical_url" do
      let(:location) { create(:location, ical_url: nil) }

      it "does not attach a calendar file" do
        described_class.new.perform(location.id, tenant.id)

        expect(location.reload.calendar_file).not_to be_attached
      end

      it "does not open any URL" do
        expect(URI).not_to receive(:open)

        described_class.new.perform(location.id, tenant.id)
      end
    end

    context "when the location has a blank ical_url" do
      let(:location) { create(:location, ical_url: "") }

      it "does not open any URL" do
        expect(URI).not_to receive(:open)

        described_class.new.perform(location.id, tenant.id)
      end
    end

    it "sets Current.tenant from the tenant_id argument" do
      allow(URI).to receive(:open).and_return(StringIO.new(ical_data))

      described_class.new.perform(location.id, tenant.id)

      expect(Current.tenant).to eq(tenant)
    end
  end
end
