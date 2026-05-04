require "rails_helper"

RSpec.describe SendLocationAnnouncementJob, type: :job do
  let(:tenant)   { Tenant.create!(key: "test", name: "Test", default: true, email_address: "noreply@test.example.com") }
  let(:location) { create(:location) }
  let(:sender)   { create(:user) }
  let(:announcement) do
    LocationAnnouncement.create!(
      location:  location,
      sent_by:   sender,
      subject:   "Welcome back!",
      body:      "We're open again."
    )
  end

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

  describe "#perform" do
    it "does nothing when the announcement does not exist" do
      expect {
        described_class.new.perform(0)
      }.not_to raise_error
    end

    context "with one recipient" do
      let!(:member) do
        user = create(:user)
        location.user_locations.create!(user: user)
        user
      end

      it "sends one email" do
        expect {
          described_class.new.perform(announcement.id)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "sends to the correct recipient" do
        described_class.new.perform(announcement.id)

        expect(ActionMailer::Base.deliveries.last.to).to include(member.email_address)
      end

      it "uses the announcement subject" do
        described_class.new.perform(announcement.id)

        expect(ActionMailer::Base.deliveries.last.subject).to eq("Welcome back!")
      end

      it "stamps sent_at on the announcement" do
        freeze_time do
          described_class.new.perform(announcement.id)

          expect(announcement.reload.sent_at).to be_within(1.second).of(Time.current)
        end
      end

      it "records the recipient count" do
        described_class.new.perform(announcement.id)

        expect(announcement.reload.recipient_count).to eq(1)
      end
    end

    context "with multiple recipients" do
      let!(:members) do
        3.times.map do
          user = create(:user)
          location.user_locations.create!(user: user)
          user
        end
      end

      it "sends one email per recipient" do
        expect {
          described_class.new.perform(announcement.id)
        }.to change { ActionMailer::Base.deliveries.count }.by(3)
      end

      it "records the correct recipient count" do
        described_class.new.perform(announcement.id)

        expect(announcement.reload.recipient_count).to eq(3)
      end
    end

    context "with no recipients" do
      it "sends no emails" do
        expect {
          described_class.new.perform(announcement.id)
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "stamps sent_at even with zero recipients" do
        described_class.new.perform(announcement.id)

        expect(announcement.reload.sent_at).to be_present
      end

      it "records recipient_count as 0" do
        described_class.new.perform(announcement.id)

        expect(announcement.reload.recipient_count).to eq(0)
      end
    end

    it "sets Current.tenant from the announcement's tenant" do
      captured_tenant = nil
      allow(LocationAnnouncementMailer).to receive(:announce) do |_user, _ann|
        captured_tenant = Current.tenant
        instance_double(ActionMailer::MessageDelivery, deliver_now: nil)
      end

      member = create(:user)
      location.user_locations.create!(user: member)

      described_class.new.perform(announcement.id)

      expect(captured_tenant).to eq(tenant)
    end

    it "clears Current.tenant after completion" do
      described_class.new.perform(announcement.id)

      expect(Current.tenant).to be_nil
    end
  end
end
