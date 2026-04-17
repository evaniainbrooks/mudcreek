class PodiumController < ApplicationController
  allow_unauthenticated_access

  def index
    set_meta_tags(
      title:       "Podium — White-label commerce platform",
      description: "Podium is a multi-tenant commerce platform for auctions, listings, rentals, and more.",
      og:          { title: "Podium", description: "The white-label commerce platform." }
    )
  end
end
