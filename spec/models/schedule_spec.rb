require "rails_helper"

RSpec.describe Schedule, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:location) }
    it { is_expected.to have_many(:schedule_events).dependent(:destroy) }
    it { is_expected.to have_one(:kiosk).dependent(:nullify) }
  end

  describe ".ordered" do
    it "orders by name" do
      z = create(:schedule, name: "Zumba Schedule")
      a = create(:schedule, name: "Adult Schedule")
      expect(Schedule.ordered.to_a).to eq([a, z])
    end
  end
end
