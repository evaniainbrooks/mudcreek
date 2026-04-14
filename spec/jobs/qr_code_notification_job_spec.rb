require "rails_helper"

RSpec.describe QrCodeNotificationJob, type: :job do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:notify_user) { create(:user) }
  let(:qr_code) do
    create(:qr_code,
      notify_user: notify_user,
      last_scanned_at: 1.second.ago,
      notification_debounce_seconds: 30)
  end

  describe "#perform" do
    context "when the QR code does not exist" do
      it "does nothing" do
        expect(QrCodeMailer).not_to receive(:scan_notification)

        described_class.new.perform(-1)
      end
    end

    context "when notify_user is not set" do
      let(:qr_code) { create(:qr_code, notify_user: nil, last_scanned_at: 1.second.ago) }

      it "does not send a notification" do
        expect(QrCodeMailer).not_to receive(:scan_notification)

        described_class.new.perform(qr_code.id)
      end
    end

    context "when the scan is within the debounce window" do
      before { qr_code.update!(last_scanned_at: 1.second.ago, notification_debounce_seconds: 3600) }

      it "does not send a notification" do
        expect(QrCodeMailer).not_to receive(:scan_notification)

        described_class.new.perform(qr_code.id)
      end
    end

    context "when the last scan is older than the debounce window" do
      before { qr_code.update!(last_scanned_at: 2.hours.ago, notification_debounce_seconds: 30) }

      it "sends the scan notification email" do
        mail = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
        allow(QrCodeMailer).to receive(:scan_notification).with(qr_code).and_return(mail)
        expect(mail).to receive(:deliver_now)

        described_class.new.perform(qr_code.id)
      end
    end

    context "when last_scanned_at is exactly at the debounce boundary" do
      before { qr_code.update!(last_scanned_at: 31.seconds.ago, notification_debounce_seconds: 30) }

      it "sends the scan notification email" do
        mail = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
        allow(QrCodeMailer).to receive(:scan_notification).with(qr_code).and_return(mail)
        expect(mail).to receive(:deliver_now)

        described_class.new.perform(qr_code.id)
      end
    end
  end
end
