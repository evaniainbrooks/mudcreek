require "rails_helper"

RSpec.describe DiscountCode, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:discount_type) }
    it { is_expected.to validate_presence_of(:amount_cents) }

    it "rejects a zero amount" do
      code = build(:discount_code, amount_cents: 0)

      expect(code).not_to be_valid
    end

    it "rejects duplicate keys within the same tenant (case-insensitive)" do
      create(:discount_code, key: "SAVE10")
      duplicate = build(:discount_code, key: "save10")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:key]).to be_present
    end

    it "rejects end_at before start_at" do
      code = build(:discount_code, start_at: 1.day.from_now, end_at: 1.hour.from_now)

      expect(code).not_to be_valid
      expect(code.errors[:end_at]).to be_present
    end

    it "rejects end_at equal to start_at" do
      time = 1.day.from_now
      code = build(:discount_code, start_at: time, end_at: time)

      expect(code).not_to be_valid
    end
  end

  describe "#active?" do
    it "returns true when no date constraints are set" do
      code = build(:discount_code, start_at: nil, end_at: nil)

      expect(code.active?).to be true
    end

    it "returns false before start_at" do
      code = build(:discount_code, start_at: 1.hour.from_now, end_at: nil)

      expect(code.active?).to be false
    end

    it "returns false after end_at" do
      code = build(:discount_code, start_at: nil, end_at: 1.hour.ago)

      expect(code.active?).to be false
    end

    it "returns true within the active window" do
      code = build(:discount_code, start_at: 1.day.ago, end_at: 1.day.from_now)

      expect(code.active?).to be true
    end

    it "returns true when start_at is in the past and end_at is nil" do
      code = build(:discount_code, start_at: 1.day.ago, end_at: nil)

      expect(code.active?).to be true
    end
  end
end
