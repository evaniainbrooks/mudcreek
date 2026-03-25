class Location < ApplicationRecord
  include MultiTenant
  include HasHashid

  has_many :check_ins, dependent: :destroy
  has_one :address, as: :addressable, dependent: :destroy
  has_one_attached :logo
  has_one_attached :background
  has_one_attached :calendar_file
  accepts_nested_attributes_for :address, reject_if: :all_blank

  has_rich_text :message

  validates :name, presence: true

  scope :ordered, -> { order(:name) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end
end
