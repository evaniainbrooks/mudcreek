module AuctionsHelper
  def set_auction_meta_tags(auction)
    description = auction.description.to_plain_text.truncate(200)
    og_image    = auction.poster.attached? ? absolute_url_for(auction.poster) : nil
    set_meta_tags title: auction.name,
      description: description,
      og: { title: auction.name, description: description, image: og_image },
      twitter: {
        card: (og_image ? "summary_large_image" : "summary"),
        title: auction.name, description: description, image: og_image
      }
  end
end
