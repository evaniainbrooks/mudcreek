require "rails_helper"

RSpec.describe "Listings", type: :system do
  before { driven_by :rack_test }

  let(:owner) { create(:user) }

  describe "tabs" do
    let!(:on_sale_listing) { create(:listing, owner: owner, published: true, state: :on_sale) }
    let!(:sold_listing)    { create(:listing, owner: owner, published: true, state: :sold) }

    it "shows On Sale as the active tab by default" do
      visit listings_path

      expect(page).to have_css(".nav-link.active", text: "On Sale")
    end

    it "shows on sale listings on the On Sale tab" do
      visit listings_path

      expect(page).to have_text(on_sale_listing.name)
      expect(page).not_to have_text(sold_listing.name)
    end

    it "shows the Sold tab" do
      visit listings_path

      expect(page).to have_link("Sold")
    end

    it "marks the Sold tab as active when visiting the sold tab" do
      visit listings_path(tab: "sold")

      expect(page).to have_css(".nav-link.active", text: "Sold")
    end

    it "shows sold listings on the Sold tab" do
      visit listings_path(tab: "sold")

      expect(page).to have_text(sold_listing.name)
      expect(page).not_to have_text(on_sale_listing.name)
    end

    it "does not show unpublished listings on the On Sale tab" do
      unpublished = create(:listing, owner: owner, published: false, state: :on_sale)

      visit listings_path

      expect(page).not_to have_text(unpublished.name)
    end

    it "does not show unpublished listings on the Sold tab" do
      unpublished = create(:listing, owner: owner, published: false, state: :sold)

      visit listings_path(tab: "sold")

      expect(page).not_to have_text(unpublished.name)
    end

    it "preserves the active tab when switching categories" do
      category = create(:listings_category)
      on_sale_listing.categories << category

      visit listings_path(tab: "sold")
      select category.name, from: "category_id"

      expect(page).to have_css(".nav-link.active", text: "Sold")
    end
  end

  describe "sold tab empty state" do
    it "shows a message when there are no sold listings" do
      visit listings_path(tab: "sold")

      expect(page).to have_text("No sold listings yet.")
    end

    it "links back to the on sale tab" do
      visit listings_path(tab: "sold")
      click_link "Browse listings for sale"

      expect(page).to have_css(".nav-link.active", text: "On Sale")
    end
  end
end
