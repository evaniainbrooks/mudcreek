require "rails_helper"

RSpec.describe "Admin::Listings::Categories", type: :system do
  before { driven_by :rack_test }

  let(:current_user) { create(:user, :super_admin) }

  before { sign_in_as(current_user) }

  describe "index" do
    let!(:category) { create(:listings_category) }

    it "shows the heading and table" do
      visit admin_listings_categories_path

      expect(page).to have_text("Listing Categories")
      expect(page).to have_css("table")
    end

    it "shows the category name" do
      visit admin_listings_categories_path

      expect(page).to have_text(category.name)
    end

    it "shows the assignment count" do
      visit admin_listings_categories_path

      expect(page).to have_text("0")
    end

    it "shows a Delete button for categories with no assignments" do
      visit admin_listings_categories_path

      expect(page).to have_button("Delete")
    end

    it "shows In use for categories with assignments" do
      listing = create(:listing)
      listing.categories << category

      visit admin_listings_categories_path

      expect(page).to have_text("In use")
      expect(page).not_to have_button("Delete")
    end

    it "shows the updated assignment count after assigning a listing" do
      listing = create(:listing)
      listing.categories << category

      visit admin_listings_categories_path

      expect(page).to have_text("1")
    end

    it "redirects unauthenticated visitors to sign in" do
      click_link "Sign out"
      visit admin_listings_categories_path

      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "create" do
    context "with valid attributes" do
      it "creates the category and shows a success notice" do
        visit admin_listings_categories_path

        fill_in "Name", with: "Hunting Land"
        click_button "Add Category"

        expect(page).to have_text('Category "Hunting Land" was successfully created.')
        expect(page).to have_text("Hunting Land")
      end
    end

    context "with invalid attributes" do
      it "shows a validation error for a blank name" do
        visit admin_listings_categories_path

        click_button "Add Category"

        expect(page).to have_text("Name can't be blank")
      end

      it "shows a validation error for a duplicate name" do
        create(:listings_category, name: "Ranches")

        visit admin_listings_categories_path

        fill_in "Name", with: "Ranches"
        click_button "Add Category"

        expect(page).to have_text("Name has already been taken")
      end
    end
  end

  describe "destroy" do
    let!(:category) { create(:listings_category) }

    it "deletes the category and shows a success notice" do
      visit admin_listings_categories_path

      name = category.name
      click_button "Delete"

      expect(page).to have_text("Category \"#{name}\" was successfully deleted.")
      expect(page).to have_current_path(admin_listings_categories_path)
      expect(page).not_to have_css("tbody", text: name)
    end
  end
end
