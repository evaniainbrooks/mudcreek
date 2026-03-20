require "rails_helper"

RSpec.describe Admin::LotsHelper, type: :helper do
  let(:tenant) { create(:tenant, key: "test") }
  let(:owner)  { create(:user) }
  let(:lot)    { create(:lot, owner: owner) }
  let(:users)  { [ owner ] }

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

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
