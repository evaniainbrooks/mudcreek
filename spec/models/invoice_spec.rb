require "rails_helper"

RSpec.describe Invoice, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:user) { create(:user) }

  def build_invoice(attrs = {})
    Invoice.new({ user: user, total_cents: 10_000, status: :unpaid }.merge(attrs))
  end

  describe "validations" do
    it "requires number" do
      invoice = build_invoice
      invoice.save!
      invoice.number = ""
      expect(invoice).not_to be_valid
    end

    it "enforces number uniqueness" do
      invoice1 = build_invoice
      invoice1.save!
      invoice2 = build_invoice
      invoice2.save!
      invoice2.number = invoice1.number
      expect(invoice2).not_to be_valid
    end

    it "enforces offer_id uniqueness when present" do
      offer = create(:offer)
      build_invoice(offer: offer).save!
      invoice2 = build_invoice(offer: offer)
      expect(invoice2).not_to be_valid
      expect(invoice2.errors[:offer_id]).to be_present
    end
  end

  describe "auto-assigned number" do
    it "assigns an INV- number before creation" do
      invoice = build_invoice
      invoice.save!
      expect(invoice.number).to match(/\AINV-[A-Z0-9]{10}\z/)
    end

    it "does not overwrite an existing number" do
      invoice = build_invoice
      invoice.number = "INV-CUSTOM"
      invoice.save!
      expect(invoice.number).to eq("INV-CUSTOM")
    end
  end

  describe "#to_param" do
    it "returns the invoice number" do
      invoice = build_invoice
      invoice.save!
      expect(invoice.to_param).to eq(invoice.number)
    end
  end
end
