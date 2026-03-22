class Tenant::Features
  include StoreModel::Model

  attribute :auctions,      :boolean, default: false
  attribute :oauth_login,   :boolean, default: false
  attribute :sold_listings, :boolean, default: false
end
