require "rails_helper"

RSpec.describe User, type: :model do
  describe "email normalization" do
    it "strips leading and trailing whitespace" do
      user = create(:user, email_address: "  user@example.com  ")

      expect(user.email_address).to eq("user@example.com")
    end

    it "downcases the email address" do
      user = create(:user, email_address: "USER@EXAMPLE.COM")

      expect(user.email_address).to eq("user@example.com")
    end

    it "strips and downcases together" do
      user = create(:user, email_address: "  USER@EXAMPLE.COM  ")

      expect(user.email_address).to eq("user@example.com")
    end
  end

  describe "password authentication" do
    let(:user) { create(:user, password: "correct_password") }

    it "returns the user when the password is correct" do
      expect(user.authenticate("correct_password")).to eq(user)
    end

    it "returns false when the password is incorrect" do
      expect(user.authenticate("wrong_password")).to be(false)
    end
  end

  describe "sessions association" do
    it "destroys associated sessions when the user is destroyed" do
      user = create(:user)
      user.sessions.create!(user_agent: "Test Agent", ip_address: "127.0.0.1")

      expect { user.destroy }.to change(Session, :count).by(-1)
    end
  end

  describe ".ransackable_attributes" do
    it "permits email_address and created_at" do
      result = User.ransackable_attributes

      expect(result).to contain_exactly("email_address", "created_at")
    end

    it "does not permit password_digest" do
      result = User.ransackable_attributes

      expect(result).not_to include("password_digest")
    end
  end
end
