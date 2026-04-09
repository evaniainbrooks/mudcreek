class Ledger < ApplicationRecord
  include MultiTenant
  include HasHashid

  has_many :entries, class_name: "Ledger::Entry", dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(:name) }
end
