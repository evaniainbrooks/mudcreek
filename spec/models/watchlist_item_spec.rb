require "rails_helper"

RSpec.describe WatchlistItem, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "rejects a duplicate listing per user" do
      item = create(:watchlist_item)
      duplicate = WatchlistItem.new(user: item.user, listing: item.listing)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:listing_id]).to be_present
    end

    it "allows the same listing to be watched by different users" do
      item    = create(:watchlist_item)
      other   = WatchlistItem.new(user: create(:user), listing: item.listing)
      expect(other).to be_valid
    end
  end
end
