require "rails_helper"

RSpec.describe Admin::DiscountCodesHelper, type: :helper do
  let(:tenant) { create(:tenant, key: "test") }
  let(:fixed_code) { create(:discount_code, key: "SAVE10", discount_type: :fixed, amount_cents: 1000) }
  let(:percentage_code) { create(:discount_code, :percentage, key: "HALF15") }

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

  describe "#render_discount_codes_table" do
    subject(:html) { Capybara.string(helper.render_discount_codes_table(discount_codes: [ fixed_code, percentage_code ]).to_s) }

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders the Key column header" do
      expect(html).to have_css("th", text: "Key")
    end

    it "renders the Type column header" do
      expect(html).to have_css("th", text: "Type")
    end

    it "renders the Amount column header" do
      expect(html).to have_css("th", text: "Amount")
    end

    it "renders the Start column header" do
      expect(html).to have_css("th", text: "Start")
    end

    it "renders the End column header" do
      expect(html).to have_css("th", text: "End")
    end

    it "renders the Actions column header" do
      expect(html).to have_css("th", text: "Actions")
    end

    it "renders a row for each discount code" do
      expect(html).to have_css("tbody tr", count: 2)
    end

    context "with a fixed discount code" do
      subject(:html) { Capybara.string(helper.render_discount_codes_table(discount_codes: [ fixed_code ]).to_s) }

      it "renders the key in a monospace span" do
        expect(html).to have_css("span.font-monospace.fw-semibold", text: "SAVE10")
      end

      it "renders the type badge with secondary styling" do
        expect(html).to have_css("span.badge.text-bg-secondary", text: "Fixed")
      end

      it "renders the amount as a currency value" do
        expect(html).to have_text("$10.00")
      end
    end

    context "with a percentage discount code" do
      subject(:html) { Capybara.string(helper.render_discount_codes_table(discount_codes: [ percentage_code ]).to_s) }

      it "renders the type badge with primary styling" do
        expect(html).to have_css("span.badge.text-bg-primary", text: "Percentage")
      end

      it "renders the amount as a percentage" do
        expect(html).to have_text("15%")
      end
    end

    context "when start_at and end_at are nil" do
      subject(:html) { Capybara.string(helper.render_discount_codes_table(discount_codes: [ fixed_code ]).to_s) }

      it "renders a muted dash for Start" do
        expect(html).to have_css("span.text-muted", text: "—")
      end
    end

    context "when start_at and end_at are set" do
      let(:code_with_dates) { create(:discount_code, :active) }

      subject(:html) { Capybara.string(helper.render_discount_codes_table(discount_codes: [ code_with_dates ]).to_s) }

      it "renders the start date" do
        expect(html).to have_text(code_with_dates.start_at.to_fs(:short))
      end

      it "renders the end date" do
        expect(html).to have_text(code_with_dates.end_at.to_fs(:short))
      end
    end

    context "actions column" do
      subject(:html) { Capybara.string(helper.render_discount_codes_table(discount_codes: [ fixed_code ]).to_s) }

      it "renders a delete button for each code" do
        expect(html).to have_css("button", text: "Delete")
      end

      it "renders the delete form targeting the discount code path" do
        expect(html).to have_css("form[action='#{admin_discount_code_path(fixed_code)}']")
      end

      it "sets a turbo confirm message including the code key" do
        expect(html).to have_css("form[data-turbo-confirm*='SAVE10']", visible: :all)
      end
    end
  end
end
