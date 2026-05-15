require "rails_helper"

RSpec.describe "Admin::Listings::Variants", type: :system do
  before { driven_by :rack_test }

  let(:current_user) { create(:user, :super_admin) }
  let(:listing) { create(:listing, owner: current_user) }

  before do
    Current.tenant.update!(features: { listing_variants: true })
    sign_in_as(current_user)
  end

  describe "generate variants" do
    let!(:size_option) do
      option = listing.options.create!(name: "Size", position: 1)
      option.option_values.create!([
        { value: "S", position: 1 },
        { value: "M", position: 2 },
        { value: "L", position: 3 }
      ])
      option
    end

    it "shows the Generate from Options button when no variants exist" do
      visit edit_admin_listing_path(listing)

      expect(page).to have_link("Generate from Options")
    end

    it "creates one variant per option value combination" do
      page.driver.post(admin_listing_variants_path(listing))
      listing.reload

      expect(listing.variants.count).to eq(3)
    end

    it "shows a success notice after generating" do
      page.driver.post(admin_listing_variants_path(listing))
      visit edit_admin_listing_path(listing)

      expect(page).to have_text("Variants generated.")
    end

    it "shows generated variants in the table" do
      page.driver.post(admin_listing_variants_path(listing))
      visit edit_admin_listing_path(listing)

      expect(page).to have_text("S")
      expect(page).to have_text("M")
      expect(page).to have_text("L")
    end

    it "does not create duplicate variants when called twice" do
      page.driver.post(admin_listing_variants_path(listing))
      page.driver.post(admin_listing_variants_path(listing))
      listing.reload

      expect(listing.variants.count).to eq(3)
    end

    context "with two options" do
      let!(:color_option) do
        option = listing.options.create!(name: "Color", position: 2)
        option.option_values.create!([
          { value: "Red", position: 1 },
          { value: "Blue", position: 2 }
        ])
        option
      end

      it "creates a variant for every combination" do
        page.driver.post(admin_listing_variants_path(listing))
        listing.reload

        expect(listing.variants.count).to eq(6)
        expect(listing.variants.map(&:display_name)).to match_array([
          "S / Red", "S / Blue",
          "M / Red", "M / Blue",
          "L / Red", "L / Blue"
        ])
      end
    end
  end
end
