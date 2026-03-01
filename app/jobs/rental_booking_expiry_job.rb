class RentalBookingExpiryJob < ApplicationJob
  queue_as :default

  def perform
    RentalBooking.where("expires_at <= ?", Time.current).find_each do |booking|
      booking.cart_item.destroy
    end
  end
end
