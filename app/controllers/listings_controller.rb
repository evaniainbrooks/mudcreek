class ListingsController < ApplicationController
  allow_unauthenticated_access

  def show
    @listing = Listing.where(published: true)
                      .with_rich_text_description
                      .with_attached_images
                      .with_attached_videos
                      .with_attached_documents
                      .includes(lot: [ :owner, :address, { listing_placeholder_attachment: :blob } ],
                                auction_listing: :auction)
                      .find_by!(hashid: params[:hashid])

    if (al = @listing.auction_listing)
      return redirect_to auction_auction_listing_path(al.auction, al)
    end
    @next_listing = Listing.where(published: true).not_in_auction
                           .where("position > ?", @listing.position)
                           .order(position: :asc, id: :asc)
                           .first
    @cart_item = if Current.user
      Current.user.cart_items.find_by(listing_id: @listing.id)
    elsif session[:guest_cart_token]
      CartItem.find_by(guest_cart_token: session[:guest_cart_token], listing_id: @listing.id)
    end
    @watchlist_item = Current.user&.watchlist_items&.find_by(listing: @listing)
    if @listing.rental?
      @booking_events = @listing.rental_bookings
        .where("expires_at > ?", Time.current)
        .map { |b| { title: "Booked", start: b.start_at.iso8601, end: b.end_at.iso8601, color: "#6B3A2A" } }
    end
  end

  def index
    @categories = Listings::Category.order(:name)
    @tab = params[:tab].presence_in(%w[on_sale sold]) || "on_sale"
    @category_hashid = params[:category_id].presence
    @search = params[:search].presence
    category = @category_hashid && Listings::Category.find_by(hashid: @category_hashid)

    @lot_hashid = params[:lot_id].presence
    lot = @lot_hashid && Lot.find_by(hashid: @lot_hashid)

    base = Listing.where(published: true, state: @tab).not_in_auction
    @filter_total = base.count
    scope = base.with_rich_text_description.with_attached_images.with_attached_videos.includes(:rental_rate_plans, :categories, lot: [ :owner, :address, { listing_placeholder_attachment: :blob } ]).order(position: :asc, id: :asc)
    scope = scope.where(id: Listings::CategoryAssignment.where(listings_category_id: category.id).select(:listing_id)) if category
    scope = scope.where(Listing.arel_table[:name].matches("%#{Listing.sanitize_sql_like(@search)}%")) if @search
    scope = scope.where(lot_id: lot.id) if lot
    @filter_count = (@search || @category_hashid || @lot_hashid) ? scope.count : @filter_total
    @pagy, @listings = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("listings", partial: "listings/listing", collection: @listings, as: :listing),
          turbo_stream.replace("sentinel", partial: "listings/sentinel", locals: { pagy: @pagy, category_id: @category_hashid, tab: @tab, search: @search })
        ]
      end
    end
  end
end
