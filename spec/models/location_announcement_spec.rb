require "rails_helper"

RSpec.describe LocationAnnouncement, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:location) }
    it { is_expected.to belong_to(:sent_by).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:body) }
  end

  describe "#sent?" do
    it "returns false when sent_at is nil" do
      announcement = build(:location_announcement, sent_at: nil)
      expect(announcement.sent?).to be false
    end

    it "returns true when sent_at is set" do
      announcement = build(:location_announcement, sent_at: Time.current)
      expect(announcement.sent?).to be true
    end
  end

  describe ".ordered" do
    it "orders by created_at descending" do
      old_one = create(:location_announcement, created_at: 2.days.ago)
      new_one = create(:location_announcement, created_at: 1.day.ago)
      expect(LocationAnnouncement.ordered.to_a).to eq([new_one, old_one])
    end
  end
end
