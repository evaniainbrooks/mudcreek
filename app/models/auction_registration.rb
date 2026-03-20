class AuctionRegistration < ApplicationRecord
  include NativeEnum

  belongs_to :auction
  belongs_to :user

  native_enum :state, %i[pending approved rejected]

  validates :user_id, uniqueness: { scope: :auction_id }

  has_many :bids, dependent: :destroy
  has_many :proxy_bids, dependent: :destroy

  before_create :apply_auto_approve
  after_create_commit  :send_approval_email, if: -> { approved? }
  after_update_commit  :send_approval_email, if: -> { saved_change_to_state?(to: "approved") }

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

  def send_approval_email
    AuctionMailer.registration_approved(self).deliver_later
  end
end
