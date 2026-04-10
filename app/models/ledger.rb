class Ledger < ApplicationRecord
  include MultiTenant
  include HasHashid

  belongs_to :location, optional: true

  has_many :entries, class_name: "Ledger::Entry", dependent: :destroy

  validates :name, presence: true

  def tax_rate
    location&.tax_rate || SALES_TAX_RATE
  end

  scope :ordered, -> { order(:name) }
end
