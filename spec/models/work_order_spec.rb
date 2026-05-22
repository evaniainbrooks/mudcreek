require "rails_helper"

RSpec.describe WorkOrder, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:work_order_items).dependent(:destroy) }
    it { is_expected.to have_many(:work_order_milestones).dependent(:destroy) }
    it { is_expected.to have_many(:invoices).through(:work_order_milestones) }
    it { is_expected.to have_one(:address).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }

    it "requires a number after creation" do
      wo = build(:work_order)
      wo.save!
      wo.number = ""
      expect(wo).not_to be_valid
    end

    it "enforces number uniqueness" do
      wo1 = create(:work_order)
      wo2 = build(:work_order)
      wo2.save!
      wo2.number = wo1.number
      expect(wo2).not_to be_valid
    end

    context "client contact" do
      it "is valid with guest fields only" do
        wo = build(:work_order, user: nil, client_name: "Alice", client_email: nil, client_phone: nil)
        expect(wo).to be_valid
      end

      it "is valid with a linked user and no guest fields" do
        user = create(:user)
        wo   = build(:work_order, user:, client_name: nil, client_email: nil, client_phone: nil)
        expect(wo).to be_valid
      end

      it "is invalid with no user and no contact details" do
        wo = build(:work_order, user: nil, client_name: nil, client_email: nil, client_phone: nil)
        expect(wo).not_to be_valid
        expect(wo.errors[:base]).to be_present
      end
    end
  end

  describe "number auto-assignment" do
    it "assigns a WO- prefixed number on create" do
      wo = create(:work_order)
      expect(wo.number).to match(/\AWO-[A-Z0-9]{10}\z/)
    end

    it "does not overwrite a pre-set number" do
      wo = build(:work_order)
      wo.number = "WO-CUSTOM"
      wo.save!
      expect(wo.number).to eq("WO-CUSTOM")
    end
  end

  describe "#to_param" do
    it "returns the number" do
      wo = create(:work_order)
      expect(wo.to_param).to eq(wo.number)
    end
  end

  describe "#guest?" do
    it "returns true when there is no linked user" do
      wo = build(:work_order, user: nil, client_name: "Guest")
      expect(wo.guest?).to be true
    end

    it "returns false when a user is linked" do
      user = create(:user)
      wo   = build(:work_order, user:, client_name: nil, client_email: nil, client_phone: nil)
      expect(wo.guest?).to be false
    end
  end

  describe "#client_display_name" do
    it "returns the user's full name when a user is linked" do
      user = create(:user, first_name: "Bob", last_name: "Builder")
      wo   = build(:work_order, :with_user, user:)
      expect(wo.client_display_name).to eq(user.name)
    end

    it "falls back to client_name for guest work orders" do
      wo = build(:work_order, user: nil, client_name: "Alice")
      expect(wo.client_display_name).to eq("Alice")
    end
  end

  describe "#client_contact_email" do
    it "returns the user's email when a user is linked" do
      user = create(:user, email_address: "bob@example.com")
      wo   = build(:work_order, :with_user, user:)
      expect(wo.client_contact_email).to eq("bob@example.com")
    end

    it "falls back to client_email for guest work orders" do
      wo = build(:work_order, user: nil, client_email: "alice@example.com")
      expect(wo.client_contact_email).to eq("alice@example.com")
    end
  end

  describe "#recompute_total" do
    it "sums line item totals before saving" do
      wo = create(:work_order)
      create(:work_order_item, work_order: wo, quantity: 2, unit_price_cents: 10_000)
      create(:work_order_item, work_order: wo, quantity: 1, unit_price_cents: 5_000)

      wo.reload.save!
      expect(wo.reload.total_cents).to eq(25_000)
    end

    it "recalculates when items are updated" do
      wo   = create(:work_order)
      item = create(:work_order_item, work_order: wo, quantity: 1, unit_price_cents: 10_000)

      item.update!(unit_price_cents: 20_000)
      wo.save!

      expect(wo.reload.total_cents).to eq(20_000)
    end

    it "sets total to zero when there are no items" do
      wo = create(:work_order)
      wo.save!
      expect(wo.total_cents).to eq(0)
    end
  end

  describe "state enum" do
    it "defaults to draft" do
      wo = build(:work_order)
      expect(wo.state).to eq("draft")
    end

    it "exposes all expected states" do
      expect(WorkOrder.states.keys).to eq(%w[draft estimate_sent contracted in_progress completed cancelled])
    end
  end
end
