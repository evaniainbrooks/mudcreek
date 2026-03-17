class UserCategoryInterest < ApplicationRecord
  include MultiTenant

  belongs_to :user
  belongs_to :category, class_name: "Listings::Category", foreign_key: :listings_category_id

  validates :listings_category_id, uniqueness: { scope: :user_id }

  # Idempotently records interest in every category on the given listing for
  # the given user. Safe to call repeatedly — duplicates are silently ignored.
  def self.record_for(user:, listing:)
    category_ids = listing.category_ids
    return if category_ids.empty?

    now = Time.current
    rows = category_ids.map do |cid|
      {
        user_id:              user.id,
        listings_category_id: cid,
        tenant_id:            listing.tenant_id,
        created_at:           now,
        updated_at:           now
      }
    end

    insert_all(rows, unique_by: [:user_id, :listings_category_id])
  end
end
