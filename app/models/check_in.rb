class CheckIn < ApplicationRecord
  include MultiTenant

  belongs_to :user, optional: true
  belongs_to :location

  validates :guest_name, presence: true, if: -> { user_id.nil? }

  scope :this_week,  -> { where(created_at: 1.week.ago..) }
  scope :this_month, -> { where(created_at: 1.month.ago..) }
  scope :ordered,    -> { order(created_at: :desc) }
end
