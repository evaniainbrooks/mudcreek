require "rails_helper"

RSpec.describe Transaction, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:order) { create(:order) }

  describe "associations" do
    it "belongs to an order" do
      t = Transaction.create!(order: order, amount_cents: 1000)
      expect(t.order).to eq(order)
    end
  end

  describe "validations" do
    it "requires uuid" do
      t = Transaction.new(order: order, amount_cents: 1000)
      t.uuid = nil
      # bypass ensure_uuid so we can test the validation itself
      allow(t).to receive(:ensure_uuid)
      expect(t).not_to be_valid
      expect(t.errors[:uuid]).to be_present
    end

    it "requires amount_cents" do
      t = Transaction.new(order: order, uuid: SecureRandom.uuid, amount_cents: nil)
      allow(t).to receive(:ensure_uuid)
      expect(t).not_to be_valid
      expect(t.errors[:amount_cents]).to be_present
    end

    it "rejects a duplicate uuid" do
      fixed_uuid = SecureRandom.uuid
      Transaction.create!(order: order, uuid: fixed_uuid, amount_cents: 1000)
      duplicate = Transaction.new(order: order, uuid: fixed_uuid, amount_cents: 500)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:uuid]).to be_present
    end

    it "allows only one succeeded transaction per order" do
      Transaction.create!(order: order, amount_cents: 1000, state: :succeeded)
      second = Transaction.new(order: order, amount_cents: 1000, state: :succeeded)
      expect(second).not_to be_valid
      expect(second.errors[:order_id]).to be_present
    end

    it "allows multiple non-succeeded transactions on the same order" do
      Transaction.create!(order: order, amount_cents: 1000, state: :pending)
      second = Transaction.new(order: order, amount_cents: 1000, state: :pending)
      expect(second).to be_valid
    end
  end

  describe "uuid auto-generation" do
    it "generates a uuid before create when none is set" do
      t = Transaction.create!(order: order, amount_cents: 1000)
      expect(t.uuid).to be_present
    end

    it "does not overwrite an explicitly provided uuid" do
      custom_uuid = SecureRandom.uuid
      t = Transaction.create!(order: order, amount_cents: 1000, uuid: custom_uuid)
      expect(t.uuid).to eq(custom_uuid)
    end
  end
end
