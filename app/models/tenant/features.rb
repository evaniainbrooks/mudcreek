class Tenant::Features
  include StoreModel::Model

  attribute :auctions,         :boolean, default: false
  attribute :kids,             :boolean, default: false
  attribute :locations,        :boolean, default: false
  attribute :oauth_login,      :boolean, default: false
  attribute :sold_listings,    :boolean, default: false
  attribute :watchlist,        :boolean, default: false
  attribute :listing_variants,    :boolean, default: false
  attribute :user_verifications,  :boolean, default: false
  attribute :hide_powered_by,     :boolean, default: false

  DESCRIPTIONS = {
    auctions:         "Enable auction listings, bidding, and registration.",
    kids:             "Track children/kids associated with user accounts.",
    locations:        "Enable physical locations with QR code check-in and showroom display.",
    watchlist:        "Allow users to save listings to a personal watchlist.",
    sold_listings:    "Show a Sold tab on the public listings page.",
    listing_variants:   "Allow listings to define options (e.g. Size, Color) with per-variant stock and pricing.",
    user_verifications: "Require users to upload a verification document before accessing the platform.",
    oauth_login:      "Enable sign-in with third-party OAuth providers.",
    hide_powered_by:  'Hide the "Powered by Podium" label in the site footer.'
  }.freeze
end
