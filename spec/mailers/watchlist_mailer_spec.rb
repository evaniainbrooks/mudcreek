require "rails_helper"

RSpec.describe WatchlistMailer, type: :mailer do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:user)           { create(:user) }
  let(:listing)        { create(:listing) }
  let(:watchlist_item) { create(:watchlist_item, user: user, listing: listing) }

  describe "#listing_state_changed" do
    subject(:mail) { WatchlistMailer.listing_state_changed(watchlist_item) }

    it "sends to the watchlist user" do
      expect(mail.to).to eq([user.email_address])
    end

    it "includes the listing name in the subject" do
      expect(mail.subject).to include(listing.name)
    end

    it "includes the listing state in the HTML body" do
      listing.update_column(:state, "sold")
      mail = WatchlistMailer.listing_state_changed(watchlist_item)
      expect(mail.html_part.body.to_s).to include("Sold")
    end

    it "includes the listing state in the text body" do
      listing.update_column(:state, "cancelled")
      mail = WatchlistMailer.listing_state_changed(watchlist_item)
      expect(mail.text_part.body.to_s).to include("Cancelled")
    end

    it "includes a link to the listing" do
      expect(mail.html_part.body.to_s).to include(listing.hashid)
    end
  end
end

RSpec.describe "WatchlistItem state change notifications", type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:listing) { create(:listing) }

  it "enqueues an email for each watcher when the listing state changes", :skip_n_plus_one do
    watcher_one = create(:watchlist_item, listing: listing)
    watcher_two = create(:watchlist_item, listing: listing)

    expect {
      listing.update!(state: :sold)
    }.to have_enqueued_mail(WatchlistMailer, :listing_state_changed).exactly(2).times
  end

  it "does not enqueue emails when a non-state attribute changes" do
    create(:watchlist_item, listing: listing)

    expect {
      listing.update!(name: "New Name")
    }.not_to have_enqueued_mail(WatchlistMailer, :listing_state_changed)
  end

  it "does not enqueue emails when there are no watchers" do
    expect {
      listing.update!(state: :sold)
    }.not_to have_enqueued_mail(WatchlistMailer, :listing_state_changed)
  end
end
