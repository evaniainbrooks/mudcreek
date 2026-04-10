require "rails_helper"

RSpec.describe Ledger::Entry, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:ledger) { create(:ledger) }

  def build_entry(attrs = {})
    Ledger::Entry.new(
      { ledger: ledger, description: "Coffee sales", entry_type: "credit", amount: 10.00, taxed: false }.merge(attrs)
    )
  end

  describe "validations" do
    it "requires description" do
      expect(build_entry(description: "")).not_to be_valid
    end

    it "requires entry_type" do
      entry = build_entry(entry_type: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:entry_type]).to be_present
    end

    it "rejects amount of zero" do
      expect(build_entry(amount: 0)).not_to be_valid
    end

    it "rejects a negative amount" do
      expect(build_entry(amount: -5)).not_to be_valid
    end

    it "allows a nil amount" do
      expect(build_entry(amount: nil)).to be_valid
    end
  end

  describe "scopes" do
    let!(:credit) { create(:ledger_entry, ledger: ledger, entry_type: "credit") }
    let!(:debit)  { create(:ledger_entry, ledger: ledger, entry_type: "debit") }

    it ".credits returns only credit entries" do
      expect(Ledger::Entry.credits).to include(credit)
      expect(Ledger::Entry.credits).not_to include(debit)
    end

    it ".debits returns only debit entries" do
      expect(Ledger::Entry.debits).to include(debit)
      expect(Ledger::Entry.debits).not_to include(credit)
    end
  end

  describe "#subtotal" do
    it "returns the amount directly when not taxed" do
      entry = build_entry(amount: 10.00, taxed: false)
      expect(entry.subtotal).to eq(10.00)
    end

    it "backs the tax out of the amount when taxed" do
      location     = create(:location, tax_rate: 0.10)
      taxed_ledger = create(:ledger, location: location)
      entry        = Ledger::Entry.new(ledger: taxed_ledger, description: "Sale", entry_type: "credit",
                                       amount: 11.00, taxed: true)
      expect(entry.subtotal).to eq(10.00)
    end

    it "returns nil when amount is nil" do
      expect(build_entry(amount: nil).subtotal).to be_nil
    end
  end

  describe "#tax_amount" do
    it "returns 0 when not taxed" do
      expect(build_entry(amount: 10.00, taxed: false).tax_amount).to eq(0)
    end

    it "returns the tax portion when taxed" do
      location     = create(:location, tax_rate: 0.10)
      taxed_ledger = create(:ledger, location: location)
      entry        = Ledger::Entry.new(ledger: taxed_ledger, description: "Sale", entry_type: "credit",
                                       amount: 11.00, taxed: true)
      expect(entry.tax_amount).to eq(1.00)
    end

    it "returns 0 when amount is nil" do
      expect(build_entry(amount: nil).tax_amount).to eq(0)
    end
  end
end
