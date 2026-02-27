require "rails_helper"

RSpec.describe Admin::LotsHelper, type: :helper do
  let(:tenant) { create(:tenant, key: "test") }
  let(:owner)  { create(:user) }
  let(:lot)    { create(:lot, owner: owner) }
  let(:users)  { [ owner ] }

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

  describe "#lot_inline_edit_owner_cell" do
    subject(:html) { Capybara.string(helper.lot_inline_edit_owner_cell(lot, users).to_s) }

    context "when there are no validation errors" do
      it "wraps the cell in an inline-edit controller div scoped to the owner field" do
        expect(html).to have_css("div##{dom_id(lot)}_owner_id[data-controller='inline-edit']")
      end

      it "shows the owner email in the display span" do
        expect(html).to have_css("span.inline-editable", text: owner.email_address)
      end

      it "does not hide the display span" do
        expect(html).not_to have_css("span.inline-editable[hidden]", visible: :all)
      end

      it "hides the form div" do
        expect(html).to have_css("div[hidden][data-inline-edit-target='form']", visible: :all)
      end

      it "stores the owner id as the display span data-value" do
        expect(html).to have_css("span[data-value='#{owner.id}']")
      end

      it "populates the owner select with users" do
        expect(html).to have_css("select option", text: owner.email_address, visible: :all)
      end
    end

    context "when the lot has owner validation errors" do
      before { lot.errors.add(:owner, "must exist") }

      it "hides the display span" do
        expect(html).to have_css("span.inline-editable[hidden]", visible: :all)
      end

      it "shows the form div" do
        expect(html).not_to have_css("div[hidden][data-inline-edit-target='form']", visible: :all)
      end

      it "renders the error message" do
        expect(html).to have_css(".text-danger", text: "must exist")
      end

      it "applies is-invalid to the select" do
        expect(html).to have_css("select.is-invalid")
      end
    end
  end

  describe "#lot_placeholder_cell" do
    subject(:html) { Capybara.string(helper.lot_placeholder_cell(lot).to_s) }

    context "when no placeholder is attached" do
      it "wraps the cell in a div with the lot's placeholder dom id" do
        expect(html).to have_css("div##{dom_id(lot)}_listing_placeholder")
      end

      it "renders a file input accepting images" do
        expect(html).to have_css("input[type='file'][accept='image/*']")
      end

      it "renders an upload submit button" do
        expect(html).to have_css("button[type='submit']")
      end
    end

    context "when a placeholder is attached" do
      let(:placeholder) do
        double("listing_placeholder", attached?: true, variant: "fake-image-path.jpg")
      end

      before do
        allow(lot).to receive(:listing_placeholder).and_return(placeholder)
        allow(helper).to receive(:image_tag).and_return('<img src="fake-image-path.jpg" class="rounded">'.html_safe)
      end

      it "does not render a file input" do
        expect(html).not_to have_css("input[type='file']")
      end

      it "renders a delete button form" do
        expect(html).to have_css("form[action='#{admin_lot_listing_placeholder_path(lot)}']")
      end

      it "renders an image" do
        expect(html).to have_css("img")
      end
    end
  end

  describe "#render_lots_table" do
    subject(:html) { Capybara.string(helper.render_lots_table(lots: [ lot ], users: users).to_s) }

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders the Name column header" do
      expect(html).to have_css("th", text: "Name")
    end

    it "renders the Number column header" do
      expect(html).to have_css("th", text: "Number")
    end

    it "renders the Owner column header" do
      expect(html).to have_css("th", text: "Owner")
    end

    it "renders the Placeholder column header" do
      expect(html).to have_css("th", text: "Placeholder")
    end

    it "renders the Listings column header" do
      expect(html).to have_css("th", text: "Listings")
    end

    it "renders the Actions column header" do
      expect(html).to have_css("th", text: "Actions")
    end

    it "renders a row for each lot" do
      expect(html).to have_css("tbody tr", count: 1)
    end
  end
end
