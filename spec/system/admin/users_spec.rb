require "rails_helper"

RSpec.describe "Admin::Users index", type: :system do
  before { driven_by :rack_test }

  let(:current_user) { create(:user) }

  before { sign_in_as(current_user) }

  it "shows the users heading and table" do
    expect(page).to have_text("Users")
    expect(page).to have_css("table")
  end

  it "links each email as a mailto" do
    expect(page).to have_link(current_user.email_address,
                              href: "mailto:#{current_user.email_address}")
  end

  it "redirects unauthenticated visitors to sign in" do
    # Sign out first
    click_link "Sign out"
    visit admin_users_path
    expect(page).to have_current_path(new_session_path)
  end

  describe "email search" do
    let!(:other) { create(:user) }

    it "filters the table to matching users" do
      visit admin_users_path
      fill_in "Email", with: current_user.email_address
      click_button "Search"
      expect(page).to have_text(current_user.email_address)
      expect(page).not_to have_text(other.email_address)
    end

    it "shows all users after clearing the search" do
      visit admin_users_path
      fill_in "Email", with: current_user.email_address
      click_button "Search"
      click_link "Clear"
      expect(page).to have_text(current_user.email_address)
      expect(page).to have_text(other.email_address)
    end
  end

  describe "sorting" do
    it "sorts by email address" do
      click_link "Email"
      expect(current_url).to include("email_address")
      expect(page).to have_css("table")
    end

    it "sorts by created at" do
      click_link "Created At"
      expect(current_url).to include("created_at")
      expect(page).to have_css("table")
    end

    it "clears the page cursor when changing sort" do
      create_list(:user, 25)
      visit admin_users_path
      click_link "Next"
      expect(current_url).to include("page=")

      click_link "Email"
      expect(current_url).not_to include("page=")
      expect(page).to have_css("table")
    end
  end

  describe "pagination" do
    before { create_list(:user, 25) }

    it "shows a Next link when results exceed the page size" do
      visit admin_users_path
      expect(page).to have_link("Next")
    end

    it "advances to the next page" do
      visit admin_users_path
      click_link "Next"
      expect(current_url).to include("page=")
      expect(page).to have_css("table")
    end
  end
end
