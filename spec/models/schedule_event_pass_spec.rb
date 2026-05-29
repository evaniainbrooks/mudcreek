require "rails_helper"

RSpec.describe ScheduleEventPass, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:schedule_event_registrations).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:credits_remaining) }
    it { is_expected.to validate_numericality_of(:credits_remaining).is_greater_than_or_equal_to(0) }
  end

  describe ".active" do
    it "includes passes with credits remaining and no expiry" do
      pass = create(:schedule_event_pass, credits_remaining: 5, expires_at: nil)
      expect(ScheduleEventPass.active).to include(pass)
    end

    it "includes passes with a future expiry date" do
      pass = create(:schedule_event_pass, credits_remaining: 3, expires_at: 1.week.from_now)
      expect(ScheduleEventPass.active).to include(pass)
    end

    it "excludes passes with zero credits" do
      pass = create(:schedule_event_pass, credits_remaining: 0)
      expect(ScheduleEventPass.active).not_to include(pass)
    end

    it "excludes passes that have expired" do
      pass = create(:schedule_event_pass, credits_remaining: 5, expires_at: 1.day.ago)
      expect(ScheduleEventPass.active).not_to include(pass)
    end
  end
end
