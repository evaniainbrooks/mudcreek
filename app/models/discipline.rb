class Discipline < ApplicationRecord
  include MultiTenant

  has_many :ranks, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :tenant_id }

  scope :ordered, -> { order(:name) }
end
