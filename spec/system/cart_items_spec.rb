require "rails_helper"

RSpec.describe "Cart items", type: :system do
  before { driven_by :rack_test }

  let(:owner)   { create(:user) }
  let(:listing) do
    create(:listing, owner: owner, published: true, quantity: 1, listing_type: "rental")
  end
  let(:user) { create(:user) }

  before do
    create(:listings_rental_rate_plan, listing: listing)
    sign_in_as(user)
  end

  describe "adding overlapping rentals" do
    let(:start_a) { 3.days.from_now.beginning_of_hour }
    let(:end_a)   { 5.days.from_now.beginning_of_hour }
    let(:start_b) { 4.days.from_now.beginning_of_hour }
    let(:end_b)   { 6.days.from_now.beginning_of_hour }

    def add_rental(start_at, end_at)
      page.driver.post(cart_items_path, {
        listing_id:      listing.id,
        rental_start_at: start_at.strftime("%Y-%m-%dT%H:%M"),
        rental_end_at:   end_at.strftime("%Y-%m-%dT%H:%M")
      })
    end

    before { add_rental(start_a, end_a) }

    it "shows an error when adding an overlapping rental period" do
      add_rental(start_b, end_b)
      visit listing_path(listing)

      expect(page).to have_text("not available for the selected period")
    end

    it "does not add the overlapping rental to the cart" do
      expect { add_rental(start_b, end_b) }.not_to change { CartItem.count }
    end
  end
end
