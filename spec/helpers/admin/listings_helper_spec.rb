require "rails_helper"

RSpec.describe Admin::ListingsHelper, type: :helper do
  let(:tenant) { create(:tenant) }

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

  describe "#render_listing_offers_table" do
    let(:listing) { create(:listing) }
    let(:buyer)   { create(:user) }
    let(:offer)   { create(:offer, listing: listing, user: buyer, amount_cents: 7500, message: "I love it") }

    subject(:html) { Capybara.string(helper.render_listing_offers_table([offer]).to_s) }

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders the Buyer column header" do
      expect(html).to have_css("th", text: "Buyer")
    end

    it "renders the Amount column header" do
      expect(html).to have_css("th", text: "Amount")
    end

    it "renders the State column header" do
      expect(html).to have_css("th", text: "State")
    end

    it "renders the Message column header" do
      expect(html).to have_css("th", text: "Message")
    end

    it "renders the Submitted column header" do
      expect(html).to have_css("th", text: "Submitted")
    end

    it "renders a row for each offer" do
      expect(html).to have_css("tbody tr", count: 1)
    end

    it "renders a View link for each offer" do
      expect(html).to have_link("View")
    end

    context "with an empty offers list" do
      subject(:html) { Capybara.string(helper.render_listing_offers_table([]).to_s) }

      it "renders a table with no rows" do
        expect(html).to have_css("table")
        expect(html).to have_css("tbody tr", count: 0)
      end
    end
  end
end
