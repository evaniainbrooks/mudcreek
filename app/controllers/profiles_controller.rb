class ProfilesController < ApplicationController
  PURCHASED_LISTINGS_PER_PAGE = 12
  BID_REGISTRATIONS_PER_PAGE = 20

  def edit
    @user = Current.user
    @user.build_address unless @user.address
    @orders = @user.orders.includes(:order_items).order(created_at: :desc)
    @invoices = @user.invoices.includes(:auction, offer: :listing).order(created_at: :desc)
    @pagy_registrations, @bid_registrations = pagy(bid_registrations_scope, limit: BID_REGISTRATIONS_PER_PAGE)
    @pagy_listings, @purchased_listings = pagy(purchased_listings_scope, limit: PURCHASED_LISTINGS_PER_PAGE)
    @cards = SquareCustomerService.new(@user).list_cards rescue []
    @default_card_id = @user.default_square_card_id
  end

  def profile_auctions
    @pagy_registrations, @bid_registrations = pagy(bid_registrations_scope, limit: BID_REGISTRATIONS_PER_PAGE)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("bid-registrations", partial: "profiles/bid_registration", collection: @bid_registrations, as: :registration),
          turbo_stream.replace("bid-registrations-sentinel", partial: "profiles/bid_registrations_sentinel", locals: { pagy: @pagy_registrations })
        ]
      end
    end
  end

  def profile_listings
    @pagy_listings, @purchased_listings = pagy(purchased_listings_scope, limit: PURCHASED_LISTINGS_PER_PAGE)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("purchased-listings", partial: "profiles/purchased_listing", collection: @purchased_listings, as: :listing),
          turbo_stream.replace("purchased-listings-sentinel", partial: "profiles/purchased_listings_sentinel", locals: { pagy: @pagy_listings })
        ]
      end
    end
  end

  def watchlist
    @watchlist_items = Current.user.watchlist_items
      .includes(listing: [ :images_attachments, :categories, lot: :listing_placeholder_attachment ])
      .order(created_at: :desc)
  end

  def auction_bids
    @auction = Auction.find_by!(hashid: params[:hashid])
    @registration = Current.user.auction_registrations.find_by!(auction: @auction)

    @listing_bids = @registration.bids
      .where(state: "placed")
      .includes(auction_listing: :listing)
      .order(amount_cents: :desc)
      .group_by(&:auction_listing)

    ended_ids = @listing_bids.keys.select { |al| al.ends_at < Time.current }.map(&:id)
    if ended_ids.any?
      top_bids = Bid
        .select("DISTINCT ON (auction_listing_id) auction_listing_id, auction_registration_id")
        .where(auction_listing_id: ended_ids, state: "placed")
        .order("auction_listing_id, amount_cents DESC, created_at DESC")
      @won_listing_ids = top_bids
        .select { |b| b.auction_registration_id == @registration.id }
        .map(&:auction_listing_id).to_set
    else
      @won_listing_ids = Set.new
    end
  end

  def update
    @user = Current.user
    @user.build_address unless @user.address

    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: "Profile updated successfully."
    else
      @orders = @user.orders.includes(:order_items).order(created_at: :desc)
      @invoices = @user.invoices.includes(:auction, offer: :listing).order(created_at: :desc)
      @pagy_registrations, @bid_registrations = pagy(bid_registrations_scope, limit: BID_REGISTRATIONS_PER_PAGE)
      @pagy_listings, @purchased_listings = pagy(purchased_listings_scope, limit: PURCHASED_LISTINGS_PER_PAGE)
      @cards = SquareCustomerService.new(@user).list_cards rescue []
      @default_card_id = @user.default_square_card_id
      render :edit, status: :unprocessable_content
    end
  end

  private

  def bid_registrations_scope
    Current.user.auction_registrations
      .joins(:bids)
      .includes(:auction)
      .merge(Bid.where(state: "placed"))
      .distinct
      .order("auctions.ends_at DESC")
  end

  def purchased_listings_scope
    Listing
      .joins(order_items: :order)
      .where(orders: { user: Current.user, status: :paid })
      .with_attached_images
      .includes(:lot)
      .distinct
      .order(id: :desc)
  end

  def profile_params
    params.require(:user).permit(
      :first_name, :last_name,
      address_attributes: [ :street_address, :city, :province, :postal_code, :country ]
    )
  end
end
