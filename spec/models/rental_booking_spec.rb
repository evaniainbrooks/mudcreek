require "rails_helper"

RSpec.describe RentalBooking, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:listing)   { create(:listing, listing_type: :rental, quantity: 1) }
  let(:cart_item) { create(:cart_item, listing: listing) }

  def booking_for(listing, cart_item, start_at:, end_at:, expires_at: 24.hours.from_now)
    build(:rental_booking, listing: listing, cart_item: cart_item,
          start_at: start_at, end_at: end_at, expires_at: expires_at)
  end

  describe "associations" do
    it { is_expected.to belong_to(:listing) }
    it { is_expected.to belong_to(:cart_item) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:start_at) }
    it { is_expected.to validate_presence_of(:end_at) }

    it "is valid with start before end" do
      booking = booking_for(listing, cart_item, start_at: 1.day.from_now, end_at: 2.days.from_now)

      expect(booking).to be_valid
    end
  end

  describe "#end_after_start" do
    it "is invalid when end_at equals start_at" do
      time    = 1.day.from_now
      booking = booking_for(listing, cart_item, start_at: time, end_at: time)

      expect(booking).not_to be_valid
      expect(booking.errors[:end_at]).to include("must be after start time")
    end

    it "is invalid when end_at is before start_at" do
      booking = booking_for(listing, cart_item, start_at: 2.days.from_now, end_at: 1.day.from_now)

      expect(booking).not_to be_valid
      expect(booking.errors[:end_at]).to include("must be after start time")
    end
  end

  describe "#no_overlap" do
    let(:start_a) { 3.days.from_now }
    let(:end_a)   { 5.days.from_now }

    before do
      other_cart_item = create(:cart_item, listing: listing, user: create(:user))
      create(:rental_booking, listing: listing, cart_item: other_cart_item,
             start_at: start_a, end_at: end_a, expires_at: 24.hours.from_now)
    end

    it "rejects a booking that fully overlaps an existing one" do
      booking = booking_for(listing, cart_item, start_at: start_a, end_at: end_a)

      expect(booking).not_to be_valid
      expect(booking.errors[:base]).to include("This equipment is not available for the selected period")
    end

    it "rejects a booking that partially overlaps (starts during existing)" do
      booking = booking_for(listing, cart_item, start_at: 4.days.from_now, end_at: 6.days.from_now)

      expect(booking).not_to be_valid
    end

    it "rejects a booking that partially overlaps (ends during existing)" do
      booking = booking_for(listing, cart_item, start_at: 2.days.from_now, end_at: 4.days.from_now)

      expect(booking).not_to be_valid
    end

    it "allows a booking that ends exactly when the existing one starts" do
      booking = booking_for(listing, cart_item, start_at: 1.day.from_now, end_at: start_a)

      expect(booking).to be_valid
    end

    it "allows a booking that starts exactly when the existing one ends" do
      booking = booking_for(listing, cart_item, start_at: end_a, end_at: 7.days.from_now)

      expect(booking).to be_valid
    end

    it "allows an overlapping booking when listing quantity permits it" do
      listing.update!(quantity: 2)
      booking = booking_for(listing, cart_item, start_at: start_a, end_at: end_a)

      expect(booking).to be_valid
    end

    it "ignores expired bookings when checking overlap" do
      listing2    = create(:listing, listing_type: :rental, quantity: 1)
      cart_item2  = create(:cart_item, listing: listing2)
      other_cart  = create(:cart_item, listing: listing2, user: create(:user))
      create(:rental_booking, listing: listing2, cart_item: other_cart,
             start_at: start_a, end_at: end_a, expires_at: 1.hour.ago)

      booking = booking_for(listing2, cart_item2, start_at: start_a, end_at: end_a)

      expect(booking).to be_valid
    end
  end
end
