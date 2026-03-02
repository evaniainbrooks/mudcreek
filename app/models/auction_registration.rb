class AuctionRegistration < ApplicationRecord
  include NativeEnum

  belongs_to :auction
  belongs_to :user

  native_enum :state, %i[pending approved rejected]

  validates :user_id, uniqueness: { scope: :auction_id }

  before_create :apply_auto_approve

  def self.ransackable_attributes(_auth_object = nil)
    %w[state created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user auction]
  end

  private

  def apply_auto_approve
    self.state = :approved if auction.auto_approve?
  end
end
