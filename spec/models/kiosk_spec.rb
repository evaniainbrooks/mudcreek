require "rails_helper"

RSpec.describe Kiosk, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:location) { create(:location) }
  let(:kiosk)    { location.kiosk }

  describe "auto-creation" do
    it "is created automatically when a location is created" do
      expect(kiosk).to be_persisted
      expect(kiosk.location).to eq(location)
    end
  end

  describe "validations" do
    it "prevents a second kiosk for the same location" do
      duplicate = Kiosk.new(location: location)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:location_id]).to be_present
    end

    it "allows nil schedule" do
      kiosk.schedule = nil
      expect(kiosk).to be_valid
    end

    it "prevents two kiosks sharing the same schedule" do
      schedule = create(:schedule)
      kiosk.update!(schedule: schedule)
      other_kiosk = create(:location).kiosk
      other_kiosk.schedule = schedule
      expect(other_kiosk).not_to be_valid
      expect(other_kiosk.errors[:schedule_id]).to be_present
    end
  end

  describe "#today_birthday_names" do
    it "returns an empty array when the location has no members" do
      expect(kiosk.today_birthday_names).to eq([])
    end
  end
end
