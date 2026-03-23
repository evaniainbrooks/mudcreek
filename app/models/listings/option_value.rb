class Listings::OptionValue < ApplicationRecord
  self.table_name = "listings_option_values"

  belongs_to :option, class_name: "Listings::Option"
  has_many :variant_option_values, class_name: "Listings::VariantOptionValue",
           foreign_key: :option_value_id, dependent: :destroy

  acts_as_list scope: :option

  before_validation :set_default_position, on: :create

  validates :value, presence: true
  validates :position, presence: true

  private

  def set_default_position
    self.position ||= self.class.where(option_id: option_id).maximum(:position).to_i + 1
  end
end
