require "rails_helper"

RSpec.describe ScheduleEventRegistration, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:schedule_event_session) }
    it { is_expected.to belong_to(:schedule_event_pass).optional }
    it { is_expected.to have_one(:check_in).dependent(:destroy) }
  end

  describe "validations" do
    it "prevents duplicate confirmed registration for the same user and session" do
      reg   = create(:schedule_event_registration, status: :confirmed)
      dupe  = build(:schedule_event_registration,
                    user: reg.user,
                    schedule_event_session: reg.schedule_event_session,
                    status: :confirmed)
      expect(dupe).not_to be_valid
      expect(dupe.errors[:user_id]).to be_present
    end

    it "allows a second registration when the first is cancelled" do
      reg = create(:schedule_event_registration, status: :cancelled)
      new_reg = build(:schedule_event_registration,
                      user: reg.user,
                      schedule_event_session: reg.schedule_event_session,
                      status: :confirmed)
      expect(new_reg).to be_valid
    end
  end

  describe "pass credit management" do
    let(:pass) { create(:schedule_event_pass, credits_remaining: 3) }

    it "deducts a credit on create when confirmed with a pass" do
      create(:schedule_event_registration, status: :confirmed, schedule_event_pass: pass)
      expect(pass.reload.credits_remaining).to eq(2)
    end

    it "does not deduct a credit when no pass is attached" do
      create(:schedule_event_registration, status: :confirmed, schedule_event_pass: nil)
      expect(pass.reload.credits_remaining).to eq(3)
    end

    it "returns a credit when cancelled" do
      reg = create(:schedule_event_registration, status: :confirmed, schedule_event_pass: pass)
      expect { reg.update!(status: :cancelled) }.to change { pass.reload.credits_remaining }.by(1)
    end
  end

  describe "status enum" do
    it "defaults to confirmed" do
      reg = build(:schedule_event_registration)
      expect(reg.status).to eq("confirmed")
    end
  end
end
