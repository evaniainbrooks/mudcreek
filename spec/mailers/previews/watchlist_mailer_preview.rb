class WatchlistMailerPreview < ActionMailer::Preview
  def listing_state_changed
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    watchlist_item = WatchlistItem.includes(:user, :listing).first!
    WatchlistMailer.listing_state_changed(watchlist_item)
  end
end
