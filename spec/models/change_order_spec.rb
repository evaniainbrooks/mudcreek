require "rails_helper"

RSpec.describe ChangeOrder, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:work_order) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_numericality_of(:amount_cents).only_integer }
  end

  describe "number auto-assignment" do
    it "assigns a CO- prefixed number on create" do
      co = create(:change_order, number: nil)
      expect(co.number).to match(/\ACO-[A-Z0-9]{10}\z/)
    end

    it "does not overwrite a pre-set number" do
      co = create(:change_order, number: "CO-CUSTOM")
      expect(co.number).to eq("CO-CUSTOM")
    end
  end

  describe "#to_param" do
    it "returns the number" do
      co = create(:change_order)
      expect(co.to_param).to eq(co.number)
    end
  end

  describe "#currency" do
    it "delegates to the work order" do
      wo = create(:work_order, :contracted)
      co = build(:change_order, work_order: wo)
      expect(co.currency).to eq(wo.currency)
    end
  end

  describe "status enum" do
    it "defaults to draft" do
      co = build(:change_order)
      expect(co.status).to eq("draft")
    end

    it "can be set to signature_sent" do
      co = create(:change_order, status: "signature_sent")
      expect(co.status).to eq("signature_sent")
    end

    it "can be set to signed" do
      co = create(:change_order, status: "signed")
      expect(co.status).to eq("signed")
    end
  end
end
