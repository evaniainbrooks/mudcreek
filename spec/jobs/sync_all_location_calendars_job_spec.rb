require "rails_helper"

RSpec.describe SyncAllLocationCalendarsJob do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "#perform" do
    it "enqueues SyncLocationCalendarJob for each location with an ical_url" do
      location_a = create(:location, ical_url: "https://example.com/a.ics")
      location_b = create(:location, ical_url: "https://example.com/b.ics")

      expect {
        described_class.new.perform
      }.to have_enqueued_job(SyncLocationCalendarJob)
        .with(location_a.id, location_a.tenant_id)
        .and have_enqueued_job(SyncLocationCalendarJob)
        .with(location_b.id, location_b.tenant_id)
    end

    it "does not enqueue jobs for locations without an ical_url" do
      create(:location, ical_url: nil)
      create(:location, ical_url: "")

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(SyncLocationCalendarJob)
    end

    it "does nothing when there are no locations" do
      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(SyncLocationCalendarJob)
    end
  end
end
