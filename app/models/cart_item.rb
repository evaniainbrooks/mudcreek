class CartItem < ApplicationRecord
  include MultiTenant

  belongs_to :user
  belongs_to :listing

  validates :listing_id, uniqueness: { scope: :user_id }
end
