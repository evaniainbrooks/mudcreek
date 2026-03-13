require "rails_helper"

RSpec.describe "Admin::Listings new with property set", type: :system do
  before { driven_by :rack_test }

  let(:current_user) { create(:user, :super_admin) }

  before { sign_in_as(current_user) }

  let!(:property_set) do
    ps = create(:listings_property_set, name: "Furniture")
    create(:listings_property, property_set: ps, name: "Material", value: "Oak", position: 1)
    create(:listings_property, property_set: ps, name: "Condition", value: "Good", position: 2)
    ps
  end

  describe "creating a listing via ?property_set_id query param" do
    it "pre-populates properties, allows editing, and saves successfully" do
      visit new_admin_listing_path(property_set_id: property_set.id)

      # Required fields
      fill_in "Name", with: "Antique Oak Dresser"
      fill_in "Price", with: "125.00"
      select current_user.email_address, from: "Owner"
      find("[name='listing[description]']", visible: :all).set("A beautiful antique dresser.")

      # Properties are pre-populated from the property set
      expect(page).to have_field("listing[properties_attributes][0][name]", with: "Material")
      expect(page).to have_field("listing[properties_attributes][0][value]", with: "Oak")
      expect(page).to have_field("listing[properties_attributes][1][name]", with: "Condition")
      expect(page).to have_field("listing[properties_attributes][1][value]", with: "Good")

      # Edit one of the pre-filled values
      fill_in "listing[properties_attributes][1][value]", with: "Excellent"

      click_button "Create Listing"

      expect(page).to have_text("Listing was successfully created.")
      expect(page).to have_text("Antique Oak Dresser")

      listing = Listing.find_by!(name: "Antique Oak Dresser")
      properties = listing.properties.order(:position)
      expect(properties.count).to eq(2)
      expect(properties.first.name).to eq("Material")
      expect(properties.first.value).to eq("Oak")
      expect(properties.second.name).to eq("Condition")
      expect(properties.second.value).to eq("Excellent")
    end
  end
end
