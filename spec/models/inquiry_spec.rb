require "rails_helper"

RSpec.describe Inquiry, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:inquiry_form) { create(:inquiry_form) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:message) }

    it "requires a valid email" do
      inquiry = Inquiry.new(inquiry_form: inquiry_form, name: "Test", message: "Hi", email: "not-an-email")
      expect(inquiry).not_to be_valid
      expect(inquiry.errors[:email]).to be_present
    end

    it "accepts a valid email" do
      inquiry = Inquiry.new(inquiry_form: inquiry_form, name: "Test", message: "Hi", email: "test@example.com")
      expect(inquiry).to be_valid
    end

    it "rejects an invalid phone format" do
      inquiry = build(:inquiry, phone: "abc-not-a-phone")
      expect(inquiry).not_to be_valid
      expect(inquiry.errors[:phone]).to be_present
    end

    it "accepts a blank phone" do
      expect(build(:inquiry, phone: nil)).to be_valid
    end

    it "accepts a valid phone" do
      expect(build(:inquiry, phone: "+1 (555) 123-4567")).to be_valid
    end
  end

  describe "#guest?" do
    it "returns true when there is no associated user" do
      expect(build(:inquiry, user: nil)).to be_guest
    end

    it "returns false when there is an associated user" do
      expect(build(:inquiry, user: create(:user))).not_to be_guest
    end
  end
end
