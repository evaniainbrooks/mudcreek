require "rails_helper"

RSpec.describe "Admin::Listings", type: :system do
  before { driven_by :rack_test }

  let(:current_user) { create(:user) }

  before { sign_in_as(current_user) }

  describe "index" do
    let!(:listing) { create(:listing, owner: current_user) }

    it "shows the listings heading and table" do
      visit admin_listings_path

      expect(page).to have_text("Listings")
      expect(page).to have_css("table")
    end

    it "links each listing name to its show page" do
      visit admin_listings_path

      expect(page).to have_link(listing.name, href: admin_listing_path(listing))
    end

    it "has a New Listing button" do
      visit admin_listings_path

      expect(page).to have_link("New Listing", href: new_admin_listing_path)
    end

    it "redirects unauthenticated visitors to sign in" do
      visit admin_listings_path
      click_link "Sign out"
      visit admin_listings_path

      expect(page).to have_current_path(new_session_path)
    end

    describe "search" do
      let!(:other_listing) { create(:listing) }

      it "filters by name" do
        visit admin_listings_path

        fill_in "Name", with: listing.name
        click_button "Search"
        expect(page).to have_link(listing.name)
        expect(page).not_to have_link(other_listing.name)
      end

      it "filters by owner email" do
        visit admin_listings_path

        fill_in "Owner Email", with: listing.owner.email_address
        click_button "Search"
        expect(page).to have_link(listing.name)
        expect(page).not_to have_link(other_listing.name)
      end

      it "shows all listings after clearing the search" do
        visit admin_listings_path

        fill_in "Name", with: listing.name
        click_button "Search"
        click_link "Clear"
        expect(page).to have_link(listing.name)
        expect(page).to have_link(other_listing.name)
      end
    end

    describe "sorting" do
      it "sorts by name" do
        visit admin_listings_path

        click_link "Name"
        expect(current_url).to include("name")
        expect(page).to have_css("table")
      end

      it "sorts by price" do
        visit admin_listings_path

        click_link "Price"
        expect(current_url).to include("price_cents")
        expect(page).to have_css("table")
      end

      it "sorts by created at" do
        visit admin_listings_path

        click_link "Created At"
        expect(current_url).to include("created_at")
        expect(page).to have_css("table")
      end

      it "clears the page cursor when changing sort" do
        create_list(:listing, 25)
        visit admin_listings_path

        click_link "Next"
        expect(current_url).to include("page=")

        click_link "Name"
        expect(current_url).not_to include("page=")
        expect(page).to have_css("table")
      end
    end

    describe "pagination" do
      before { create_list(:listing, 25) }

      it "shows a Next link when results exceed the page size" do
        visit admin_listings_path

        expect(page).to have_link("Next")
      end

      it "advances to the next page" do
        visit admin_listings_path

        click_link "Next"
        expect(current_url).to include("page=")
        expect(page).to have_css("table")
      end
    end
  end

  describe "show" do
    let(:listing) { create(:listing, owner: current_user) }


    it "displays the listing name" do
      visit admin_listing_path(listing)

      expect(page).to have_text(listing.name)
    end

    it "displays the formatted price" do
      visit admin_listing_path(listing)

      expect(page).to have_text("$10.00")
    end

    it "displays the owner email" do
      visit admin_listing_path(listing)

      expect(page).to have_text(listing.owner.email_address)
    end

    it "has an edit link" do
      visit admin_listing_path(listing)

      expect(page).to have_link("Edit", href: edit_admin_listing_path(listing))
    end

    it "has a delete button" do
      visit admin_listing_path(listing)

      expect(page).to have_button("Delete")
    end

    it "has a back link to the index" do
      visit admin_listing_path(listing)

      expect(page).to have_link("Back to Listings", href: admin_listings_path)
    end
  end

  describe "new" do
    it "shows the new listing form" do
      visit new_admin_listing_path

      expect(page).to have_text("New Listing")
      expect(page).to have_field("Name")
      expect(page).to have_field("Price")
      expect(page).to have_select("Owner")
    end
  end

  describe "create" do
    context "with valid attributes" do
      it "redirects to the show page with a success notice" do
        visit new_admin_listing_path

        fill_in "Name", with: "My New Listing"
        fill_in "Price", with: "49.99"
        select current_user.email_address, from: "Owner"
        # ActionText renders a hidden input for the rich text body
        find("[name='listing[description]']", visible: :all).set("A great listing")
        click_button "Create Listing"

        expect(page).to have_text("Listing was successfully created.")
        expect(page).to have_text("My New Listing")
      end
    end

    context "with invalid attributes" do
      it "re-renders the form with validation errors" do
        visit new_admin_listing_path
        click_button "Create Listing"

        expect(page).to have_text("prohibited this listing from being saved")
        expect(page).to have_text("Name can't be blank")
      end
    end
  end

  describe "edit" do
    let(:listing) { create(:listing, owner: current_user) }

    it "shows the edit form" do
      visit edit_admin_listing_path(listing)

      expect(page).to have_text("Edit Listing")
    end

    it "pre-populates the name field" do
      visit edit_admin_listing_path(listing)

      expect(page).to have_field("Name", with: listing.name)
    end

    it "pre-populates the price field" do
      visit edit_admin_listing_path(listing)

      expect(page).to have_field("Price", with: listing.price.to_f.to_s)
    end
  end

  describe "update" do
    let(:listing) { create(:listing, owner: current_user) }

    context "with valid attributes" do
      before do
      end

      it "redirects to the show page with a success notice" do
        visit edit_admin_listing_path(listing)

        fill_in "Name", with: "Updated Name"
        click_button "Update Listing"

        expect(page).to have_text("Listing was successfully updated.")
        expect(page).to have_text("Updated Name")
      end
    end

    context "with invalid attributes" do
      it "re-renders the form with validation errors" do
        visit edit_admin_listing_path(listing)

        fill_in "Name", with: ""
        click_button "Update Listing"

        expect(page).to have_text("prohibited this listing from being saved")
        expect(page).to have_text("Name can't be blank")
      end
    end
  end

  describe "destroy" do
    let!(:listing) { create(:listing, owner: current_user) }


    it "deletes the listing and redirects to the index with a success notice" do
      visit admin_listing_path(listing)

      name = listing.name
      click_button "Delete"
      expect(page).to have_text("Listing was successfully deleted.")
      expect(page).to have_current_path(admin_listings_path)
      expect(page).not_to have_text(name)
    end
  end
end
