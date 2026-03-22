class Profiles::AuctionsController < Profiles::BaseController
  include AuctionFeatureGated
  REGISTRATIONS_PER_PAGE = 20

  def show
    @pagy, @bid_registrations = pagy(bid_registrations_scope, limit: REGISTRATIONS_PER_PAGE)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("bid-registrations", partial: "profiles/bid_registration", collection: @bid_registrations, as: :registration),
          turbo_stream.replace("bid-registrations-sentinel", partial: "profiles/bid_registrations_sentinel", locals: { pagy: @pagy })
        ]
      end
    end
  end

  def bid_detail
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

  private

  def bid_registrations_scope
    Current.user.auction_registrations
      .joins(:bids)
      .includes(:auction)
      .merge(Bid.where(state: "placed"))
      .distinct
      .order("auctions.ends_at DESC")
  end
end
