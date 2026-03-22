class WatchlistItemsController < ApplicationController
  before_action :require_watchlist_feature!

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

  private

  def require_watchlist_feature!
    redirect_to root_path unless Current.tenant.features.watchlist?
  end
end
