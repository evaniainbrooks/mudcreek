require "rails_helper"

RSpec.describe ScheduleEventSession, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:schedule_event) }
    it { is_expected.to have_many(:schedule_event_registrations).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:occurs_on) }

    it "enforces uniqueness of occurs_on within a schedule_event" do
      session = create(:schedule_event_session)
      dupe    = build(:schedule_event_session, schedule_event: session.schedule_event, occurs_on: session.occurs_on)
      expect(dupe).not_to be_valid
      expect(dupe.errors[:schedule_event_id]).to be_present
    end

    it "allows the same date for a different schedule_event" do
      session = create(:schedule_event_session)
      other   = build(:schedule_event_session, occurs_on: session.occurs_on)
      expect(other).to be_valid
    end
  end

  describe "#confirmed_registrations" do
    it "returns only confirmed registrations" do
      session    = create(:schedule_event_session)
      confirmed  = create(:schedule_event_registration, schedule_event_session: session, status: :confirmed)
      cancelled  = create(:schedule_event_registration, schedule_event_session: session, status: :cancelled)
      expect(session.confirmed_registrations).to include(confirmed)
      expect(session.confirmed_registrations).not_to include(cancelled)
    end
  end
end
