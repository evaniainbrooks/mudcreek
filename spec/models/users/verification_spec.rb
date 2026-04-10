require "rails_helper"

RSpec.describe Users::Verification, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "enforces one verification record per user" do
      create(:users_verification)
      user   = Users::Verification.last.user
      second = Users::Verification.new(user: user, status: :not_validated)
      expect(second).not_to be_valid
      expect(second.errors[:user_id]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:validated_by).class_name("User").optional }
  end

  describe "status" do
    it "defaults to not_validated" do
      verification = create(:users_verification)
      expect(verification.status).to eq("not_validated")
    end

    it "can be set to validated" do
      verification = create(:users_verification, :validated)
      expect(verification.status).to eq("validated")
    end
  end
end
