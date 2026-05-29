require "rails_helper"

RSpec.describe ScheduleEvent, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:schedule) }
    it { is_expected.to have_many(:schedule_event_sessions).dependent(:destroy) }
    it { is_expected.to have_many(:check_ins).dependent(:nullify) }
  end

  describe "validations" do
    it "requires a uid after creation" do
      event = create(:schedule_event)
      event.uid = ""
      expect(event).not_to be_valid
      expect(event.errors[:uid]).to be_present
    end

    it "enforces uid uniqueness within a schedule" do
      event = create(:schedule_event)
      dupe  = build(:schedule_event, schedule: event.schedule, uid: event.uid)
      expect(dupe).not_to be_valid
      expect(dupe.errors[:uid]).to be_present
    end

    it "allows the same uid on a different schedule" do
      event = create(:schedule_event)
      other = build(:schedule_event, uid: event.uid)
      expect(other).to be_valid
    end
  end

  describe "uid auto-assignment" do
    it "assigns a UUID on create when uid is blank" do
      event = create(:schedule_event, uid: nil)
      expect(event.uid).to match(/\A[0-9a-f-]{36}\z/)
    end

    it "does not overwrite a pre-set uid" do
      event = create(:schedule_event, uid: "custom-uid")
      expect(event.uid).to eq("custom-uid")
    end
  end

  describe ".bookable" do
    it "returns only bookable events" do
      bookable     = create(:schedule_event, bookable: true)
      not_bookable = create(:schedule_event, bookable: false)
      expect(ScheduleEvent.bookable).to include(bookable)
      expect(ScheduleEvent.bookable).not_to include(not_bookable)
    end
  end
end
