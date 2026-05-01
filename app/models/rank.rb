class Rank < ApplicationRecord
  include MultiTenant

  belongs_to :discipline

  has_many :rank_awards, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :discipline_id }
  validates :position, presence: true

  scope :ordered, -> { order(:position) }
end
