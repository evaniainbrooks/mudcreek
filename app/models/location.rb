class Location < ApplicationRecord
  include MultiTenant
  include HasHashid

  has_many :ledgers, dependent: :nullify
  has_many :check_ins, dependent: :destroy
  has_one :qr_code, dependent: :destroy
  has_one :address, as: :addressable, dependent: :destroy
  has_one_attached :logo
  has_many_attached :backgrounds
  has_one_attached :calendar_file
  accepts_nested_attributes_for :address, reject_if: :all_blank

  has_rich_text :message

  validates :name, presence: true
  validates :tax_rate, numericality: { greater_than_or_equal_to: 0, less_than: 1 }

  def tax_rate_percent
    (tax_rate * 100).round(4)
  end

  def tax_rate_percent=(value)
    self.tax_rate = BigDecimal(value.to_s) / 100
  end

  validate :only_one_default_per_tenant, if: :default?

  scope :ordered,  -> { order(:name) }
  scope :default,  -> { find_by(default: true) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end

  private

  def only_one_default_per_tenant
    existing = Location.where(default: true).where.not(id: id)
    errors.add(:base, "Another location is already set as the default") if existing.exists?
  end
end
