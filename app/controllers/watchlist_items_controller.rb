class WatchlistItemsController < ApplicationController
  def create
    listing = Listing.find(params[:listing_id])
    @watchlist_item = Current.user.watchlist_items.find_or_create_by!(listing: listing)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to listings_path }
    end
  end

  def destroy
    @watchlist_item = Current.user.watchlist_items.find(params[:id])
    @watchlist_item.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to listings_path }
    end
  end
end
