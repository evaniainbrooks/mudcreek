require "rails_helper"

RSpec.describe Session, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it "belongs to a user" do
      user = create(:user)
      session = Session.create!(user: user)
      expect(session.user).to eq(user)
    end
  end
end
