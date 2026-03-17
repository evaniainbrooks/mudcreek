class WatchlistMailer < ApplicationMailer
  def listing_state_changed(watchlist_item)
    @user = watchlist_item.user
    @listing = watchlist_item.listing

    mail(
      to: @user.email_address,
      subject: "Update on #{@listing.name}"
    )
  end
end
