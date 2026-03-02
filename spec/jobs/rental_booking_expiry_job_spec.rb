require "rails_helper"

RSpec.describe RentalBookingExpiryJob do
  include ActiveSupport::Testing::TimeHelpers

  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "#perform" do
    it "destroys cart items for expired bookings" do
      expired = create(:rental_booking, expires_at: 1.minute.ago)
      described_class.new.perform
      expect { expired.cart_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "leaves unexpired bookings alone" do
      future = create(:rental_booking, expires_at: 1.hour.from_now)
      described_class.new.perform
      expect { future.cart_item.reload }.not_to raise_error
    end

    it "treats a booking expiring exactly now as expired" do
      freeze_time do
        boundary = create(:rental_booking, expires_at: Time.current)
        described_class.new.perform
        expect { boundary.cart_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "does nothing when there are no expired bookings" do
      create(:rental_booking, expires_at: 1.day.from_now)
      expect { described_class.new.perform }.not_to raise_error
    end

    it "only destroys expired bookings when both expired and unexpired exist" do
      expired = create(:rental_booking, expires_at: 5.minutes.ago)
      future  = create(:rental_booking, expires_at: 5.minutes.from_now)
      described_class.new.perform
      expect { expired.cart_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { future.cart_item.reload }.not_to raise_error
    end
  end
end
