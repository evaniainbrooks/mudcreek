module AuctionScopes
  extend ActiveSupport::Concern

  included do
    scope :live,     -> { where("starts_at <= NOW() AND ends_at > NOW()") }
    scope :upcoming, -> { where("starts_at > NOW()") }
    scope :ended,    -> { where("ends_at < NOW()") }

    scope :search_name, ->(query) {
      where("auctions.name ILIKE ?", "%#{sanitize_sql_like(query)}%")
    }

    scope :by_category, ->(category) {
      where(id: joins(listings: :categories).where(listings_categories: { id: category.id }).select(:id))
    }

    scope :by_status_order, -> {
      order(Arel.sql(<<~SQL.squish))
        CASE
          WHEN starts_at <= NOW() AND ends_at > NOW() THEN 0
          WHEN starts_at > NOW() THEN 1
          ELSE 2
        END,
        starts_at ASC
      SQL
    }
  end
end
