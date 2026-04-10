require "rails_helper"

RSpec.describe AuctionRegistration, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:auction) { create(:auction) }
  let(:user)    { create(:user) }

  def create_registration(attrs = {})
    AuctionRegistration.create!({ auction: auction, user: user, state: :pending }.merge(attrs))
  end

  describe "validations" do
    it "rejects a duplicate registration for the same user and auction" do
      create_registration
      duplicate = AuctionRegistration.new(auction: auction, user: user, state: :pending)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows the same user to register for different auctions" do
      other_auction = create(:auction)
      create_registration
      reg2 = AuctionRegistration.new(auction: other_auction, user: user, state: :pending)
      expect(reg2).to be_valid
    end
  end

  describe "auto-approve" do
    it "sets state to approved when the auction has auto_approve enabled" do
      auction.update!(auto_approve: true)
      reg = AuctionRegistration.create!(auction: auction, user: user)
      expect(reg.state).to eq("approved")
    end

    it "leaves state as pending when auto_approve is disabled" do
      auction.update!(auto_approve: false)
      reg = AuctionRegistration.create!(auction: auction, user: user)
      expect(reg.state).to eq("pending")
    end
  end
end
