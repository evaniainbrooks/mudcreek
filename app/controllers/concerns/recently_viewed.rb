module RecentlyViewed
  extend ActiveSupport::Concern

  MAX_RECENTLY_VIEWED = 11

  private

  def record_recently_viewed(type:, hashid:, auction_hashid: nil)
    return if bot_request?

    entry = { "type" => type.to_s, "hashid" => hashid, "auction_hashid" => auction_hashid, "viewed_at" => Time.current.utc.iso8601(3) }

    list = (session[:recently_viewed] || []).dup
    list.reject! { |e| e["type"] == entry["type"] && e["hashid"] == entry["hashid"] }
    list.unshift(entry)
    session[:recently_viewed] = list.first(MAX_RECENTLY_VIEWED)
  end

  def recently_viewed_items(exclude_type: nil, exclude_hashid: nil)
    list = (session[:recently_viewed] || []).dup
    list.reject! { |e| e["type"] == exclude_type.to_s && e["hashid"] == exclude_hashid } if exclude_type && exclude_hashid
    list = list.sort_by { |e| e["viewed_at"] || "" }.reverse
    return [] if list.empty?

    listing_hashids = list.select { |e| e["type"] == "listing" }.map { |e| e["hashid"] }
    al_hashids      = list.select { |e| e["type"] == "auction_listing" }.map { |e| e["hashid"] }

    listings_by_hashid = if listing_hashids.any?
      Listing.where(published: true, hashid: listing_hashids)
             .includes(lot: { listing_placeholder_attachment: :blob },
                       gallery: { photos_attachments: :blob })
             .index_by(&:hashid)
    else
      {}
    end

    auction_listings_by_hashid = if al_hashids.any?
      AuctionListing.joins(:auction)
                    .merge(Auction.where(published: true))
                    .where(hashid: al_hashids)
                    .includes(:auction, :current_bid,
                              listing: { lot: { listing_placeholder_attachment: :blob },
                                         gallery: { photos_attachments: :blob } })
                    .index_by(&:hashid)
    else
      {}
    end

    list.filter_map do |entry|
      case entry["type"]
      when "listing"
        record = listings_by_hashid[entry["hashid"]]
        { type: :listing, record: record } if record
      when "auction_listing"
        record = auction_listings_by_hashid[entry["hashid"]]
        { type: :auction_listing, record: record } if record
      end
    end
  end
end
