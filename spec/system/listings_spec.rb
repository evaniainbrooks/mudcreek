require "rails_helper"

RSpec.describe "Listings", type: :system do
  before { driven_by :rack_test }

  let(:owner) { create(:user) }

  describe "tabs" do
    let!(:on_sale_listing) { create(:listing, owner: owner, published: true, state: :on_sale) }
    let!(:sold_listing)    { create(:listing, owner: owner, published: true, state: :sold) }

    it "shows on sale listings by default" do
      visit listings_path

      expect(page).to have_text(on_sale_listing.name)
      expect(page).not_to have_text(sold_listing.name)
    end

    it "shows sold listings on the Sold tab" do
      visit listings_path(tab: "sold")

      expect(page).to have_text(sold_listing.name)
      expect(page).not_to have_text(on_sale_listing.name)
    end

    it "does not show unpublished listings by default" do
      unpublished = create(:listing, owner: owner, published: false, state: :on_sale)

      visit listings_path

      expect(page).not_to have_text(unpublished.name)
    end

    it "does not show unpublished listings on the Sold tab" do
      unpublished = create(:listing, owner: owner, published: false, state: :sold)

      visit listings_path(tab: "sold")

      expect(page).not_to have_text(unpublished.name)
    end
  end

  describe "sold tab empty state" do
    it "shows a message when there are no sold listings" do
      visit listings_path(tab: "sold")

      expect(page).to have_text("No sold listings yet.")
    end

    it "links back to the listings page" do
      visit listings_path(tab: "sold")
      click_link "Browse listings for sale"

      expect(page).to have_css(".nav-link.active", text: "Listings")
    end
  end
end
