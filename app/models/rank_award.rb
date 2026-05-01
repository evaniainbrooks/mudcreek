class RankAward < ApplicationRecord
  include MultiTenant

  belongs_to :rankable, polymorphic: true
  belongs_to :rank
  belongs_to :awarded_by, class_name: "User", optional: true

  has_one :discipline, through: :rank

  validates :awarded_at, presence: true
  validates :stripes, inclusion: { in: 0..4 }

  scope :ordered, -> { order(awarded_at: :desc, id: :desc) }
end
