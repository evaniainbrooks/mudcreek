require "rails_helper"

RSpec.describe Transaction, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:order) { create(:order) }

  describe "associations" do
    it { is_expected.to belong_to(:order) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_presence_of(:amount_cents) }

    it "rejects a duplicate uuid" do
      Transaction.create!(order: order, uuid: "fixed-uuid", amount_cents: 1000)
      duplicate = Transaction.new(order: order, uuid: "fixed-uuid", amount_cents: 500)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:uuid]).to be_present
    end

    it "allows only one succeeded transaction per order" do
      Transaction.create!(order: order, uuid: SecureRandom.uuid, amount_cents: 1000, state: :succeeded)
      second = Transaction.new(order: order, uuid: SecureRandom.uuid, amount_cents: 1000, state: :succeeded)
      expect(second).not_to be_valid
      expect(second.errors[:order_id]).to be_present
    end

    it "allows multiple non-succeeded transactions on the same order" do
      Transaction.create!(order: order, uuid: SecureRandom.uuid, amount_cents: 1000, state: :pending)
      second = Transaction.new(order: order, uuid: SecureRandom.uuid, amount_cents: 1000, state: :pending)
      expect(second).to be_valid
    end
  end

  describe "uuid auto-generation" do
    it "generates a uuid before create when none is set" do
      t = Transaction.create!(order: order, amount_cents: 1000)
      expect(t.uuid).to be_present
    end

    it "does not overwrite an explicitly provided uuid" do
      t = Transaction.create!(order: order, amount_cents: 1000, uuid: "my-custom-uuid")
      expect(t.uuid).to eq("my-custom-uuid")
    end
  end
end
