require "rails_helper"

RSpec.describe Order, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:user) { create(:user) }

  def build_order(attrs = {})
    Order.new({ user: user, subtotal_cents: 1000, tax_cents: 0, total_cents: 1000, status: :pending }.merge(attrs))
  end

  describe "validations" do
    it "requires number" do
      order = build_order
      order.save!
      order.number = ""
      expect(order).not_to be_valid
    end

    it "enforces number uniqueness" do
      order1 = build_order.tap(&:save!)
      order2 = build_order.tap(&:save!)
      order2.number = order1.number
      expect(order2).not_to be_valid
    end

    it "enforces guest_token uniqueness" do
      order1 = build_order(user: nil, guest_email: "a@example.com").tap(&:save!)
      order2 = build_order(user: nil, guest_email: "b@example.com").tap(&:save!)
      order2.guest_token = order1.guest_token
      expect(order2).not_to be_valid
    end

    context "user_or_guest_info_present" do
      it "is valid with a user and no guest email" do
        expect(build_order(user: user, guest_email: nil)).to be_valid
      end

      it "is valid with a guest email and no user" do
        expect(build_order(user: nil, guest_email: "guest@example.com")).to be_valid
      end

      it "is invalid with neither a user nor a guest email" do
        order = build_order(user: nil, guest_email: "")
        expect(order).not_to be_valid
        expect(order.errors[:base]).to be_present
      end
    end
  end

  describe "auto-assigned number" do
    it "assigns an MC- number on creation" do
      order = build_order.tap(&:save!)
      expect(order.number).to match(/\AMC-[A-Z0-9]{8}\z/)
    end
  end

  describe "auto-assigned guest_token" do
    it "assigns a guest token when no user is set" do
      order = build_order(user: nil, guest_email: "guest@example.com").tap(&:save!)
      expect(order.guest_token).to be_present
    end

    it "does not assign a guest token when a user is set" do
      order = build_order(user: user).tap(&:save!)
      expect(order.guest_token).to be_nil
    end
  end

  describe "#to_param" do
    it "returns the order number" do
      order = build_order.tap(&:save!)
      expect(order.to_param).to eq(order.number)
    end
  end
end
