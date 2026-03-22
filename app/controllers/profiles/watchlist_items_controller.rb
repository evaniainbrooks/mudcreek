class Profiles::WatchlistItemsController < Profiles::BaseController
  before_action { redirect_to root_path unless Current.tenant.features.watchlist? }

  def show
    @categories = Listings::Category.order(:name)
    @search = params[:search].presence
    @category_hashid = params[:category_id].presence
    category = @category_hashid && Listings::Category.find_by(hashid: @category_hashid)

    @filter_total = Current.user.watchlist_items.count
    scope = Current.user.watchlist_items
      .includes(listing: [ :images_attachments, :categories,
                           lot: [ :owner, :address, :listing_placeholder_attachment ],
                           auction_listing: [ :auction, :current_bid ] ])
      .order(created_at: :desc)
    scope = scope.joins(listing: :category_assignments).where(listings_category_assignments: { listings_category_id: category.id }) if category
    scope = scope.joins(:listing).where(Listing.arel_table[:name].matches("%#{Listing.sanitize_sql_like(@search)}%")) if @search

    @watchlist_items = scope
    @filter_count = (@search || @category_hashid) ? scope.count : @filter_total
  end
end
